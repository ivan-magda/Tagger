# Tagger

![License](https://img.shields.io/npm/l/express.svg)
![Platform iOS](https://img.shields.io/badge/platform-iOS-blue.svg)
[![codebeat badge](https://codebeat.co/badges/8192c79c-edcb-4974-8765-5ec515b414fe)](https://codebeat.co/projects/github-com-vanyaland-tagger)

<p align="center">
  <img src="https://github.com/vanyaland/Tagger/blob/master/Screenshots/main.png"/>
</p>

## Description

*Want to be popular on some social network easily?* Use Tagger to make your account content more popular and to raise your popularity.

Content like photos and videos with tags can be much easier to be searched and recommended by social networks algorithms to other users, especially the users that have the same interest in the tags. Tagger always searches for the most trending hashtags and choose the better ones related to yours. Moreover, Tagger searches hashtags in the *real-time* while other apps take the results from a static list. This allows you to get the highest results.

*Discover new hashtags that you'd never thought of that!*

### Features:
- Automatically assign tags to your images
- Image analysis and discovery
- Search tags for a given category in real time
- Gain up likes and followers with matching hashtags
- Select an image from your library, camera or Flickr camera roll
- Get a list of hot tags for the given period, for a day or a week
- Unlimited number of tag categories

## Requirements
- Swift 4.1
- Xcode 9.2

## Installation
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
