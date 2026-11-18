# Counseling Theory Pro

A personal study guide for counseling students. Five color-coded theory decks cover person-centered, cognitive behavioral, solution-focused, reality, and psychodynamic approaches. The SwiftUI app and the mobile web app use the same original flashcard bank and practice vignettes. The tree and open book come from the supplied design reference.

## Start on iPhone

Open the study site in Safari. Use Share → Add to Home Screen, enable **Open as Web App** if offered, and tap **Add**. Launch it from its icon before starting your study history. The initial visit requires internet access. The app saves cards, favorites, and quiz progress in that browser or installed web app on that device. Removing website data can clear progress.

## Run the native iPhone app

1. Download or clone this repository on a Mac and open **CounselingTheoryPro.xcodeproj**. Use Xcode 15 or newer with iOS 17 or newer support. Use an Xcode version compatible with the iOS version on your physical device.
2. Select the **CounselingTheoryPro** scheme and an iPhone simulator, then press **⌘R**. The default Debug configuration uses local storage.
3. For your physical iPhone, add your Apple Account in Xcode settings. Select the app target → Signing & Capabilities, choose your Team, and change the bundle identifier if the current one is unavailable. Select your connected iPhone and run. Follow any pairing or Developer Mode prompts on the device.

### Optional Apple services

Debug and Release work with local study data. The **Cloud** configuration also compiles a Sign in with Apple button and iCloud key-value storage for study history. A developer team must register the chosen App ID and enable Sign in with Apple and iCloud key-value storage. Check Native/Cloud.entitlements and the resulting provisioning profile. In Edit Scheme, choose Cloud for Run or Archive to exercise this build. Test on two devices signed into the same iCloud account. Sign in with Apple identifies the app user locally. The device’s iCloud account controls synchronization. Web and native study histories are independent.

### TestFlight and release

- With a developer program team, register the bundle ID and create its app record in App Store Connect.
- Select a device archive destination, then Product → Archive. Validate in Organizer and upload to App Store Connect.
- After processing, select the build in TestFlight, complete required information, and invite your internal tester. Open the invitation on iPhone through TestFlight.
- Before wider distribution, verify clean install, large text, VoiceOver, offline study, favorites and quiz persistence. For the Cloud configuration also test changing iCloud accounts, revoked credentials, signing in and signing out. Review the content with a counseling educator and complete Apple’s privacy and submission forms for the version you ship.

## Study features

- Choose a theory or follow the seven-day plan. Reveal a card, bookmark it, or look up a term.
- Use ten-question quizzes for recall and review the explanation for each answer.
- The reference desk includes six original exam-style scenarios with rationales, DSM-5-TR study concepts, official reference links and test-taking strategies.
- The dark interface uses text labels as well as theory colors.
- Browse [study sources](Sources.md). The NCE questions are independently written for study. They are unaffiliated with NBCC or APA. The DSM section is a study aid for concepts and navigation.

## Repository layout

| Path | Contents |
| --- | --- |
| CounselingTheoryPro.xcodeproj | Native iPhone project and shared scheme |
| Native | SwiftUI screens, local/cloud persistence, artwork and privacy manifest |
| web | Installable mobile web app, flashcards and exam scenarios |
| .github/workflows/ios.yml | Builds both native configurations on a macOS runner |
| ReleaseNotes.md | Candidate store description and study-data privacy summary |

To try the web version locally, run `python3 -m http.server 8000 --directory web` and open http://localhost:8000. Use HTTPS for a hosted installation and service-worker support.

## Apple documentation

- [Test on a personal device](https://developer.apple.com/help/account/basics/about-your-developer-account/)
- [Enable capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/)
- [TestFlight overview](https://developer.apple.com/testflight/)
- [Add a web app to iPhone](https://support.apple.com/guide/iphone/iphea86e5236/ios)
