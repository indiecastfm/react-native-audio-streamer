# react-native-audio-streamer

A react-native audio streaming module which works for both iOS & Android

iOS streaming is based on [DOUAudioStreamer](https://github.com/douban/DOUAudioStreamer)

Audio streaming is based on [ExoPlayer](https://github.com/google/ExoPlayer)

## Installation

- Add following dependency in your `package.json`

`"react-native-audio-streamer": "git://github.com/victor36max/react-native-audio-streamer.git"`

- Then run the following command to link to iOS & Android project

`react-native link react-native-audio-streamer`

## Usage

### Basic

```javascript
import RNAudioStreamer from 'react-native-audio-streamer';

RNAudioStreamer.setUrl('http://lacavewebradio.chickenkiller.com:8000/stream.mp3')
RNAudioStreamer.play()
RNAudioStreamer.pause()
RNAudioStreamer.seekToTime(16) //seconds
RNAudioStreamer.duration((err, duration)=>{
 if(!err) console.log(duration) //seconds
})
RNAudioStreamer.currentTime((err, currentTime)=>{
 if(!err) console.log(currentTime) //seconds
})

// Player Status:
// - PLAYING
// - PAUSED
// - STOPPED
// - FINISHED
// - BUFFERING
// - ERROR
RNAudioStreamer.status((err, status)=>{
 if(!err) console.log(status)
})

```

### Status Change Observer

```Javascript
const {
  DeviceEventEmitter
} = 'react-native'

// Status change observer
componentDidMount() {
    this.subscription = DeviceEventEmitter.addListener('RNAudioStreamerStatusChanged',this._statusChanged.bind(this))
}

// Player Status:
// - PLAYING
// - PAUSED
// - STOPPED
// - FINISHED
// - BUFFERING
// - ERROR
_statusChanged(status) {
  // Your logic
}
```



## Milestones

- Audio caching
- Buffering ratio

