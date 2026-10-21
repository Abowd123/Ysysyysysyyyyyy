"""Injects a release signingConfig into the generated Android Gradle file.
Works for both build.gradle.kts (Kotlin DSL) and build.gradle (Groovy)."""
import sys, re
path, store, alias, key_pw, store_pw = sys.argv[1:6]
s = open(path).read()
if path.endswith(".kts"):
    cfg = f'''
    signingConfigs {{
        create("release") {{
            storeFile = file("{store}")
            storePassword = "{store_pw}"
            keyAlias = "{alias}"
            keyPassword = "{key_pw}"
        }}
    }}
'''
    s = s.replace("android {", "android {" + cfg, 1)
    s = re.sub(r'signingConfig = signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', s)
else:
    cfg = f'''
    signingConfigs {{
        release {{
            storeFile file("{store}")
            storePassword "{store_pw}"
            keyAlias "{alias}"
            keyPassword "{key_pw}"
        }}
    }}
'''
    s = s.replace("android {", "android {" + cfg, 1)
    s = s.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
open(path, "w").write(s)
print("release signing applied to", path)
