"""Pure policy for the temporary acceptance harness; no bus/process/sleep actions.
A locker exit is not completion of a system sleep transaction. Unknown state
retains temporary Hypridle. A timeout requests operator recovery, never teardown.
"""
from dataclasses import dataclass, field
from enum import Enum, auto


class Phase(Enum):
    ProductionActive = auto()
    ProductionStopped = auto()
    TemporaryStarting = auto()
    TemporaryActive = auto()
    SleepRequested = auto()
    SleepPending = auto()
    Sleeping = auto()
    Resumed = auto()
    SleepFailed = auto()
    TemporaryStopping = auto()
    ProductionRestoring = auto()
    ProductionVerified = auto()


@dataclass
class Observation:
    preparing: bool | None
    sleep_service_terminal: bool
    locker_exited: bool
    # A definite logind rejection, not systemctl's early successful exit, a
    # transport timeout, or an arbitrary nonzero exit of uncertain provenance.
    request_definitively_rejected: bool = False


@dataclass
class Handoff:
    phase: Phase = Phase.ProductionActive
    failures: set[str] = field(default_factory=set)
    request_issued: bool = False
    saw_prepare: bool = False
    saw_complete: bool = False

    def advance(self, expected, target):
        if self.phase != expected:
            raise RuntimeError(f"unexpected handoff phase: {self.phase.name}")
        self.phase = target

    def production_stopped(self):
        self.advance(Phase.ProductionActive, Phase.ProductionStopped)

    def temporary_starting(self):
        self.advance(Phase.ProductionStopped, Phase.TemporaryStarting)

    def temporary_active(self, *, config_matches, inhibitor_held, exactly_one):
        if not (config_matches and inhibitor_held and exactly_one):
            raise RuntimeError("temporary Hypridle not verified")
        self.advance(Phase.TemporaryStarting, Phase.TemporaryActive)

    def sleep_requested(self, *, unlocked):
        if not unlocked or self.request_issued:
            raise RuntimeError("sleep must be requested once from unlocked")
        self.advance(Phase.TemporaryActive, Phase.SleepRequested)
        self.request_issued = True  # Set BEFORE issuing the external command.

    def prepare_signal(self, sleeping):
        if not self.request_issued:
            return
        if sleeping:
            self.saw_prepare = True
            self.saw_complete = False
            self.phase = Phase.SleepPending
        elif self.saw_prepare:
            self.saw_complete = True
            self.phase = Phase.Resumed

    def service_sleeping(self):
        if self.phase == Phase.SleepPending:
            self.phase = Phase.Sleeping

    def failure(self, kind):
        if kind not in {"LockFailed", "SleepFailed", "TemporaryFailed", "ObservationFailed", "Deadline"}:
            raise ValueError("unknown failure")
        self.failures.add(kind)  # Does NOT move to a restoration phase.

    def may_restore(self, observation):
        if observation.preparing is not False or not observation.sleep_service_terminal:
            return False
        if not observation.locker_exited:
            return False
        if not self.request_issued:
            # Also covers interruption between stopping production and persisting
            # the next phase; restoration verifies whether production is alive.
            return self.phase in {Phase.ProductionActive, Phase.ProductionStopped, Phase.TemporaryStarting, Phase.TemporaryActive}
        if observation.request_definitively_rejected:
            self.phase = Phase.SleepFailed
            return True
        # Receipt of false alone before true, or command exit alone, is insufficient.
        return self.saw_prepare and self.saw_complete and self.phase == Phase.Resumed

    def begin_restoration(self, observation):
        if not self.may_restore(observation):
            raise RuntimeError("sleep transaction unresolved: retain temporary Hypridle")
        self.phase = Phase.TemporaryStopping

    def temporary_stopped(self, *, gone):
        if not gone:
            self.failure("TemporaryFailed")
            raise RuntimeError("temporary process still exists; do not overlap")
        self.advance(Phase.TemporaryStopping, Phase.ProductionRestoring)

    def production_verified(self, *, exactly_one, config_matches, inhibitor_held, temporary_unit_absent):
        if not (exactly_one and config_matches and inhibitor_held and temporary_unit_absent):
            raise RuntimeError("production restoration not verified")
        self.advance(Phase.ProductionRestoring, Phase.ProductionVerified)
