#!/usr/bin/env python3
"""Ghostty launch scope, argv preservation and desktop-entry routing."""
import os
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch

PROTOCOL = 'ext_background_effect_manager_v1'


class Tests(unittest.TestCase):
    wrapper=Path(__file__).resolve().parents[2]/'t15g/ghostty/.local/bin/ghostty'

    def test_normal_launch_preserves_arguments_and_gpu_environment(self):
        original={'HYPRLAND_INSTANCE_SIGNATURE':'session', 'GDK_WAYLAND_DISABLE':'other',
                  'AQ_DRM_DEVICES':'unchanged', 'DRI_PRIME':'1', 'PATH':'/test'}
        with patch.dict(os.environ,original,clear=True), patch('sys.argv',['ghostty','-e','printf','a b']), patch('os.execve') as execute:
            runpy.run_path(str(self.wrapper),run_name='__main__')
            binary,args,env=execute.call_args.args
            self.assertEqual(binary,'/usr/bin/ghostty')
            self.assertEqual(args,['/usr/bin/ghostty','-e','printf','a b'])
            self.assertEqual(env['GDK_WAYLAND_DISABLE'],'other,'+PROTOCOL)
            for key in ['AQ_DRM_DEVICES','DRI_PRIME','PATH']:self.assertEqual(env[key],original[key])
            self.assertEqual(dict(os.environ),original)

    def test_normal_launch_outside_hyprland_leaves_environment_unchanged(self):
        launch=runpy.run_path(str(self.wrapper))['launch_environment']
        original={'GDK_WAYLAND_DISABLE':'other','DISPLAY':':0'}
        self.assertEqual(launch(original),original)
        env={'HYPRLAND_INSTANCE_SIGNATURE':'session','GDK_WAYLAND_DISABLE':PROTOCOL}
        self.assertEqual(launch(env),env)

    def test_desktop_launch_and_action_use_wrapper_with_single_instance(self):
        import gi
        gi.require_version('GioUnix','2.0')
        from gi.repository import GioUnix
        p=self.wrapper.parent.parent/'share/applications/com.mitchellh.ghostty.desktop'
        app=GioUnix.DesktopAppInfo.new_from_filename(str(p))
        self.assertIsNotNone(app)
        self.assertFalse(app.get_boolean('DBusActivatable'))
        self.assertEqual(app.get_string('Exec'),'ghostty --gtk-single-instance=true')
        self.assertIn('new-window',app.list_actions())
        self.assertIn('Exec=ghostty --gtk-single-instance=true',p.read_text().split('[Desktop Action new-window]')[1])


if __name__=="__main__":unittest.main()
