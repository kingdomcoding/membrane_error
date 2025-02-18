import Hls from 'hls.js';

let hlsInstance = null;

const initializePlayer = (player) => {
  let src = "";

  if (player.dataset.source !== undefined) {
    src = `${player.dataset.source}/index.m3u8`;
  }

  if (Hls.isSupported()) {
    if (!hlsInstance) {
      hlsInstance = new Hls();
    }

    hlsInstance.on(Hls.Events.MANIFEST_PARSED, function (event, data) {
      console.log('manifest loaded, playing muted video');
      player.muted = true;
      player.play();
    });

    hlsInstance.on(Hls.Events.ERROR, (event, data) => {
      switch (data.type) {
        case Hls.ErrorTypes.NETWORK_ERROR:
          if (player.dataset.source !== undefined) {
            setTimeout(() => {
              hlsInstance.loadSource(src);
            }, 1000);
          }
      }
    });

    hlsInstance.loadSource(src);
    hlsInstance.attachMedia(player);
  } else if (player.canPlayType('application/vnd.apple.mpegurl')) {
    player.src = src;
  }
};

export const Player = {
  mounted() {
    initializePlayer(this.el);
  },
  updated() {
    initializePlayer(this.el);
  }
};
