# Tagger

![License](https://img.shields.io/npm/l/express.svg)
![Platform iOS](https://img.shields.io/badge/platform-iOS-blue.svg)
[![codebeat badge](https://codebeat.co/badges/8192c79c-edcb-4974-8765-5ec515b414fe)](https://codebeat.co/projects/github-com-vanyaland-tagger)

<p align="center">
  <img src="https://github.com/vanyaland/Tagger/blob/master/Screenshots/main.png"/>
</p>

## Description

Tagger helps you increase the number of Instagram or Flickr followers and likes on your pictures.
Tagger always searches for the most trending hashtag and choose the better ones related to yours. Also, searches hashtag in real time while other apps take the results from a static list. This allows you to get the highest results on Instagram or Flickr search trends. Discover new hashtags that you'd never thought of that!

Main features:
- Automated image recognition tasks to come up with a list of tags.
- Select an image from your library, camera or Flickr camera roll.
- Get a list of hot tags for the given period, for a day or a week.
- Search tags for a given category in real time.
- Unlimited number of tag categories.

### Tagger currently uses Swift 2.2 version.

## Installation
- Run `pod install` on project directory([CocoaPods Installation](https://guides.cocoapods.org/using/getting-started.html)).
- Open `Tagger.xcworkspace` and build.
- Goto [Flickr](https://www.flickr.com/services/apps/create/) and create an App.
Get your API Key and Secret.
- Goto [Imagga](https://imagga.com/) to register for a free account and get your API Details(Key, Secret, Authorization).
- In `Constants.swift`, change the properties with your own instances.
- Build & run, enjoy.

`FlickrOAuthCallbackURL` example: `tagger://oauth-callback/flickr`.

## Components
- Keychain-Swift - https://github.com/marketplacer/keychain-swift

## Third-Party Services
- [Flickr](https://www.flickr.com/services/api/) - online photo management and sharing application.
- [Imagga](https://imagga.com/) - image recognition API.

## Author
I'm [Ivan Magda](https://www.facebook.com/ivan.magda).
Email: [imagda15@gmail.com](mailto:imagda15@gmail.com).
Twitter: [@magda_ivan](https://twitter.com/magda_ivan).

## LICENSE
This project is open-sourced software licensed under the MIT License.

See the LICENSE file for more information.

## More Images
<img src="https://github.com/vanyaland/Tagger/blob/master/Screenshots/tagging.png"
width="274" height="480" hspace="8">
<img src="https://github.com/vanyaland/Tagger/blob/master/Screenshots/results.png"
width="274" height="480" hspace="8">
