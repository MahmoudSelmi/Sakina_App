name: sakina_app
description: "A new Flutter project."

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  dio: ^5.7.0
  get_it: ^8.0.2

  just_audio: ^0.9.42
  audio_service: ^0.18.15

  cached_network_image: ^3.4.1
  flutter_screenutil: ^5.9.3
  flutter_svg: ^2.0.10+1

  shared_preferences: ^2.3.3
  path_provider: ^2.1.5
  permission_handler: ^11.3.1

  firebase_core: ^3.15.1
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.3.6

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true