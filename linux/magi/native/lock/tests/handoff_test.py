import importlib.util
from pathlib import Path
import sys
import unittest

spec = importlib.util.spec_from_file_location("handoff", Path(__file__).resolve().parents[1] / "integration/handoff_policy.py")
h = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = h
spec.loader.exec_module(h)


def active():
    p = h.Handoff()
    p.production_stopped()
    p.temporary_starting()
    p.temporary_active(config_matches=True, inhibitor_held=True, exactly_one=True)
    return p


def pending():
    p = active()
    p.sleep_requested(unlocked=True)
    p.prepare_signal(True)
    return p


class Restoration(unittest.TestCase):
    def test_full_cycle(self):
        p = pending()
        p.service_sleeping()
        p.prepare_signal(False)
        p.begin_restoration(h.Observation(False, True, True))
        p.temporary_stopped(gone=True)
        p.production_verified(exactly_one=True, config_matches=True, inhibitor_held=True, temporary_unit_absent=True)
        self.assertEqual(p.phase, h.Phase.ProductionVerified)

    def test_lock_service_failure_keeps_inhibitor(self):
        p = pending()
        p.failure("LockFailed")
        self.assertFalse(p.may_restore(h.Observation(True, True, True)))
        self.assertEqual(p.phase, h.Phase.SleepPending)

    def test_locker_exit_before_observed_prepare(self):
        p = active()
        p.sleep_requested(unlocked=True)
        p.failure("LockFailed")
        self.assertFalse(p.may_restore(h.Observation(False, True, True)))

    def test_systemctl_success_is_not_completion(self):
        p = pending()
        self.assertFalse(p.may_restore(h.Observation(True, False, True)))

    def test_failure_waits_until_real_completion(self):
        p = pending()
        p.failure("LockFailed")
        p.prepare_signal(False)
        self.assertTrue(p.may_restore(h.Observation(False, True, True)))

    def test_false_without_true_is_not_completion(self):
        p = active()
        p.sleep_requested(unlocked=True)
        p.prepare_signal(False)
        self.assertFalse(p.may_restore(h.Observation(False, True, True)))

    def test_stale_false_rejected_by_property(self):
        p = pending()
        p.prepare_signal(False)
        self.assertFalse(p.may_restore(h.Observation(True, True, True)))

    def test_unknown_property_retains_temporary(self):
        p = pending()
        p.prepare_signal(False)
        self.assertFalse(p.may_restore(h.Observation(None, True, True)))

    def test_timeout_does_not_drop_protection(self):
        p = pending()
        p.failure("Deadline")
        with self.assertRaises(RuntimeError):
            p.begin_restoration(h.Observation(True, False, True))

    def test_temporary_failure_is_not_completion(self):
        p = pending()
        p.failure("TemporaryFailed")
        self.assertFalse(p.may_restore(h.Observation(True, True, True)))

    def test_request_rejected(self):
        p = active()
        p.sleep_requested(unlocked=True)
        self.assertTrue(p.may_restore(h.Observation(False, True, True, True)))

    def test_rejection_does_not_override_pending(self):
        p = pending()
        self.assertFalse(p.may_restore(h.Observation(True, True, True, True)))

    def test_resumed_locker_still_running(self):
        p = pending()
        p.prepare_signal(False)
        self.assertFalse(p.may_restore(h.Observation(False, True, False)))

    def test_no_overlapping_idle_processes(self):
        p = pending()
        p.prepare_signal(False)
        p.begin_restoration(h.Observation(False, True, True))
        with self.assertRaises(RuntimeError):
            p.temporary_stopped(gone=False)
        self.assertNotEqual(p.phase, h.Phase.ProductionRestoring)

    def test_process_only_restoration_is_not_success(self):
        p = pending()
        p.prepare_signal(False)
        p.begin_restoration(h.Observation(False, True, True))
        p.temporary_stopped(gone=True)
        with self.assertRaises(RuntimeError):
            p.production_verified(exactly_one=True, config_matches=True, inhibitor_held=False, temporary_unit_absent=True)
        self.assertNotEqual(p.phase, h.Phase.ProductionVerified)

    def test_no_second_suspend(self):
        p = pending()
        with self.assertRaises(RuntimeError):
            p.sleep_requested(unlocked=True)

    def test_locked_start_rejected(self):
        p = active()
        with self.assertRaises(RuntimeError):
            p.sleep_requested(unlocked=False)

    def test_setup_failure_before_request(self):
        p = h.Handoff()
        p.production_stopped()
        p.temporary_starting()
        p.failure("TemporaryFailed")
        self.assertTrue(p.may_restore(h.Observation(False, True, True)))

    def test_interruption_before_phase_write(self):
        p = h.Handoff()
        self.assertTrue(p.may_restore(h.Observation(False, True, True)))
        self.assertFalse(p.may_restore(h.Observation(True, True, True)))


if __name__ == "__main__":
    unittest.main()
