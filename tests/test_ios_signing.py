"""App Store signing validation without accessing the real Keychain."""
import datetime
import hashlib
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('ios_signing', Path(__file__).resolve().parents[1] / 'prod_build/ios_signing.py')
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    def test_profile_validation(self):
        cert = b'test certificate'
        identity = hashlib.sha1(cert).hexdigest().upper()
        profile = dict(ExpirationDate=datetime.datetime(2099, 1, 1), Platform=['iOS'],
                       TeamIdentifier=['ABCDEFGHIJ'], ApplicationIdentifierPrefix=['PREFIX'],
                       UUID='12345678-1234-1234-1234-123456789abc', DeveloperCertificates=[cert],
                       Entitlements={'application-identifier': 'PREFIX.com.workorder'})
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'profile'
            source.write_bytes(b'profile')
            output = Path(directory) / 'options.plist'
            def command(args, **kwargs):
                return plistlib.dumps(profile) if args[1] == 'cms' else identity
            with patch.object(signing.subprocess, 'check_output', side_effect=command), \
                    patch.object(signing.Path, 'home', return_value=Path(directory)), \
                    patch.dict(signing.os.environ, {}, clear=True):
                signing.prepare(str(source), 'com.workorder', str(output))
                options = plistlib.loads(output.read_bytes())
                self.assertEqual(options['signingCertificate'], identity)
                self.assertEqual(options['teamID'], 'ABCDEFGHIJ')
                with self.assertRaisesRegex(ValueError, 'bundle ID'):
                    signing.prepare(str(source), 'wrong.bundle', str(output))
                profile['ProvisionedDevices'] = ['device']
                with self.assertRaisesRegex(ValueError, 'App Store profile'):
                    signing.prepare(str(source), 'com.workorder', str(output))
                del profile['ProvisionedDevices']
                profile['ExpirationDate'] = datetime.datetime(2000, 1, 1)
                with self.assertRaisesRegex(ValueError, 'expired'):
                    signing.prepare(str(source), 'com.workorder', str(output))


if __name__ == '__main__':
    unittest.main()
