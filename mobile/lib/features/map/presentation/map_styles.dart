// Quiet base maps: the photo pins carry the colour, so the map stays near the
// app's ground colour, with points of interest and transit hidden.

const kLightMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#ebebe8" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#7d7f84" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#f2f2f0" }] },
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "landscape.natural", "elementType": "geometry", "stylers": [{ "color": "#e6e7e2" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#ffffff" }] },
  { "featureType": "road", "elementType": "labels", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{ "color": "#d3d3cf" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#d6dde1" }] }
]
''';

const kDarkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#141416" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#7a7c82" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#0b0b0c" }] },
  { "featureType": "poi", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "stylers": [{ "visibility": "off" }] },
  { "featureType": "landscape.natural", "elementType": "geometry", "stylers": [{ "color": "#161816" }] },
  { "featureType": "road", "elementType": "geometry", "stylers": [{ "color": "#26262a" }] },
  { "featureType": "road", "elementType": "labels", "stylers": [{ "visibility": "off" }] },
  { "featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{ "color": "#2e2e33" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#1c2125" }] }
]
''';
