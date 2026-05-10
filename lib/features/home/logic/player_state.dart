abstract class PlayerState {}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerReady extends PlayerState {
  final String title;
  final String sheikhName;
  final String imgUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  PlayerReady({
    required this.title,
    required this.sheikhName,
    required this.imgUrl,
    required this.isPlaying,
    required this.position,
    required this.duration,
  });
}

class PlayerError extends PlayerState {
  final String message;
  PlayerError(this.message);
}
