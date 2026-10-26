#!/usr/bin/env python3
"""Validate an external App Store profile and prepare manual Xcode signing."""
import datetime
import hashlib
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys


def prepare(profile_path, bundle, output):
    profile = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', profile_path]))
    entitlements = profile.get('Entitlements', {})

    def require(condition, message):
        if not condition:
            raise ValueError(message)

    require(profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Profile has expired')
    require('iOS' in profile.get('Platform', []), 'Not an iOS profile')
    require(not entitlements.get('get-task-allow'), 'Development profile is not supported')
    require('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices'), 'App Store profile required')
    require(entitlements.get('application-identifier') in [p + '.' + bundle for p in profile.get('ApplicationIdentifierPrefix', [])], 'Profile bundle ID mismatch')
    team = profile['TeamIdentifier'][0]
    require(not os.environ.get('TEAM_ID') or os.environ['TEAM_ID'] == team, 'TEAM_ID mismatch')
    identities = subprocess.check_output(['security', 'find-identity', '-v', '-p', 'codesigning'], text=True)
    available = set(re.findall(r'\b[A-F0-9]{40}\b', identities.upper()))
    candidates = [hashlib.sha1(c).hexdigest().upper() for c in profile.get('DeveloperCertificates', [])]
    requested = os.environ.get('SIGN_IDENTITY', '').upper()
    candidates = [c for c in candidates if c in available and (not requested or c == requested)]
    require(len(candidates) == 1, 'Import distribution.p12 into Keychain; set SIGN_IDENTITY (SHA-1) if multiple identities match')
    identity = candidates[0]
    uuid = profile['UUID']
    require(re.fullmatch(r'[A-Fa-f0-9-]{36}', uuid), 'Invalid profile UUID')
    options = dict(method='app-store-connect', destination='export', teamID=team,
                   signingStyle='manual', signingCertificate=identity,
                   provisioningProfiles={bundle: uuid}, manageAppVersionAndBuildNumber=False)
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(plistlib.dumps(options))
    for directory in ('Library/MobileDevice/Provisioning Profiles', 'Library/Developer/Xcode/UserData/Provisioning Profiles'):
        target = Path.home() / directory
        target.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(profile_path, target / (uuid + '.mobileprovision'))
    print(team, uuid, identity)


if __name__ == '__main__':
    try:
        prepare(*sys.argv[1:])
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        sys.exit('ERROR: ' + str(error))
