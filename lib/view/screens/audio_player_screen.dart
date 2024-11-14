import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;

  final _playList = ConcatenatingAudioSource(children: [
    AudioSource.uri(
      Uri.parse('asset:///asset/audio/tere_bin.mp3'),
      tag: MediaItem(
          id: '0',
          title: 'Tere Bin',
          artist: 'Arijit Singh',
          artUri: Uri.parse(
              "https://images.unsplash.com/photo-1641753543685-268866ef4c6d?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")),
    ),
    AudioSource.uri(
      Uri.parse('asset:///asset/audio/tere_bin.mp3'),
      tag: MediaItem(
          id: '1',
          title: 'Kyun Aaj Kal',
          artist: 'Sonu Nigam',
          artUri: Uri.parse(
              "https://images.unsplash.com/photo-1465984111739-03a1ee4647a0?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")),
    ),
  ]);

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _audioPlayer.positionStream,
          _audioPlayer.bufferedPositionStream,
          _audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position: position,
              bufferedPosition: bufferedPosition,
              duration: duration ?? Duration.zero));

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _audioPlayer = AudioPlayer()..setAsset("asset/audio/tere_bin.mp3");
    _audioPlayer = AudioPlayer();
    _init();
  }

  _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playList);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff1848FF), Colors.black])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder(
              stream: _audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) {
                  return SizedBox();
                }
                final metadata = state!.currentSource!.tag as MediaItem;
                return MediaMetaData(
                    imageUrl: metadata.artUri.toString(),
                    title: metadata.title ?? '',
                    artist: metadata.artist ?? '');
              },
            ),
            SizedBox(
              height: 20,
            ),
            StreamBuilder(
              stream: _positionDataStream,
              builder: (context, snapShot) {
                final position = snapShot.data;
                return ProgressBar(
                  barHeight: 8,
                  baseBarColor: Colors.grey[600],
                  bufferedBarColor: Colors.grey,
                  progressBarColor: Colors.purple,
                  thumbColor: Colors.purple,
                  timeLabelTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  progress: position?.position ?? Duration.zero,
                  buffered: position?.bufferedPosition ?? Duration.zero,
                  total: position?.duration ?? Duration.zero,
                  onSeek: _audioPlayer.seek,
                );
              },
            ),
            SizedBox(
              height: 20,
            ),
            Control(audioPlayer: _audioPlayer)
          ],
        ),
      ),
    );
  }
}

class MediaMetaData extends StatelessWidget {
  MediaMetaData(
      {super.key,
      required this.imageUrl,
      required this.title,
      required this.artist});

  final String imageUrl;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, offset: Offset(2, 4), blurRadius: 4)
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          artist,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}

class Control extends StatelessWidget {
  Control({super.key, required this.audioPlayer});
  AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: audioPlayer.seekToPrevious,
          color: Colors.white,
          iconSize: 60,
          icon: Icon(Icons.skip_previous_rounded),
        ),
        StreamBuilder(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapShot) {
              final playerState = snapShot.data;
              final processingData = playerState?.processingState;
              final playing = playerState?.playing;
              if (!(playing ?? false)) {
                return IconButton(
                  onPressed: () {
                    audioPlayer.play();
                  },
                  color: Colors.white,
                  iconSize: 80,
                  icon: Icon(Icons.play_arrow_rounded),
                );
              } else if (processingData != ProcessingState.completed) {
                return IconButton(
                  onPressed: () {
                    audioPlayer.pause();
                  },
                  color: Colors.white,
                  iconSize: 80,
                  icon: Icon(Icons.pause_rounded),
                );
              }
              return Icon(
                Icons.play_arrow_rounded,
                size: 80,
                color: Colors.white,
              );
            }),
        IconButton(
          onPressed: audioPlayer.seekToNext,
          color: Colors.white,
          iconSize: 60,
          icon: Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(
      {required this.position,
      required this.bufferedPosition,
      required this.duration});
}
