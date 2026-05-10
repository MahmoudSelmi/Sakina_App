import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();

  PlayerCubit() : super(PlayerInitial()) {
    // تحديث الـ UI لحظياً مع تقدم الوقت في الصوت
    _audioPlayer.positionStream.listen((pos) {
      if (state is PlayerReady) {
        final currentState = state as PlayerReady;
        emit(
          PlayerReady(
            title: currentState.title,
            sheikhName: currentState.sheikhName,
            imgUrl: currentState.imgUrl,
            isPlaying: _audioPlayer.playing,
            position: pos,
            duration: _audioPlayer.duration ?? Duration.zero,
          ),
        );
      }
    });
  }

  Future<void> playStream(
    String url,
    String title,
    String sheikh,
    String img,
  ) async {
    try {
      emit(PlayerLoading());

      // استخراج رابط الصوت المباشر من يوتيوب
      var video = await _yt.videos.get(url);
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();

      await _audioPlayer.setUrl(audioStream.url.toString());
      _audioPlayer.play();

      emit(
        PlayerReady(
          title: title,
          sheikhName: sheikh,
          imgUrl: img,
          isPlaying: true,
          position: Duration.zero,
          duration: _audioPlayer.duration ?? Duration.zero,
        ),
      );
    } catch (e) {
      emit(PlayerError("تعذر تشغيل المقطع"));
    }
  }

  void togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seek(Duration position) => _audioPlayer.seek(position);

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    _yt.close();
    return super.close();
  }

  void stop() {}
}
