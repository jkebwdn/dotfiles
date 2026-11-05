#!/usr/bin/env python3
"""Package boundaries in disposable homes; never stow into operator state."""
from pathlib import Path
import subprocess
import tempfile
import unittest

LINUX = Path(__file__).resolve().parents[2]

class Packages(unittest.TestCase):
    def test_magi_installs_runtime_only(self):
        with tempfile.TemporaryDirectory(prefix='magi-stow-') as tmp:
            home=Path(tmp)
            subprocess.run(['stow','--dir',str(LINUX),'--target',tmp,'magi'],check=True,capture_output=True,text=True)
            self.assertTrue((home/'.config/quickshell/magi/shell.qml').is_file())
            self.assertTrue((home/'.local/bin/magi-fetch').is_file())
            for name in ('deployment','tools','docs','tests','native','experiments','README.md','AGENTS.md','.gitignore','.git'):
                self.assertFalse((home/name).exists(),name)

    def test_ghostty_excludes_license_and_keeps_launch_integration(self):
        with tempfile.TemporaryDirectory(prefix='magi-stow-') as tmp:
            home=Path(tmp)
            subprocess.run(['stow','--dir',str(LINUX/'t15g'),'--target',tmp,'ghostty'],check=True,capture_output=True,text=True)
            for name in ('.config/ghostty/config.ghostty','.local/bin/ghostty','.local/share/applications/com.mitchellh.ghostty.desktop'):
                self.assertTrue((home/name).is_file(),name)
            self.assertFalse((home/'ghostty-desktop-LICENSE').exists())

if __name__=='__main__':unittest.main()
