# TWRP Device Tree for Xiaomi 17 Ultra (Nezha)

Device tree for building **Team Win Recovery Project (TWRP)** for the **Xiaomi 17 Ultra (Nezha)**.

If you reuse this device tree or portions of it, please retain proper attribution and credit the original source.

**Maintainer:** JohnTheFarm3r

## Device Information

| Property     | Value                      |
| ------------ | -------------------------- |
| Device       | Xiaomi 17 Ultra            |
| Codename     | Nezha                      |
| Manufacturer | Xiaomi                     |
| Platform     | Qualcomm Snapdragon SM8850 |
| Architecture | arm64                      |

## Status

### Working

* Boots successfully
* Touchscreen
* Fully working data decryption
* ADB
* MTP
* USB OTG
* Brightness
* Vibrator

Most core recovery functionality is working as expected, including full data decryption.

## Known Issues

> You tell me.

## Compatibility

This device tree was built and tested against **LineageOS (LOS)** and is known to work there.

Although I have not personally tested it on **HyperOS (HOS)** and do not intend to return to HyperOS for additional testing, several users have reported successfully booting TWRP on **Xiaomi.eu build 308**. According to their feedback, both booting and data decryption work correctly.

Beyond those reports, no guarantees are made regarding compatibility with other HyperOS builds. This device tree is provided as-is.

## Credits

Special thanks to:

* Team Win Recovery Project (TWRP)
* Android Open Source Project (AOSP)
* The LineageOS Project
* The Android aftermarket development community
* Everyone who contributed code, testing, documentation, bug reports, and shared knowledge.

## License

Copyright (C) 2026 JohnTheFarm3r

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this project except in compliance with the License. You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the Apache License 2.0 should also be included in the repository as the `LICENSE` file.
