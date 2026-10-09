# Video Playlist: setup guide (Windows to iPhone)

## 1. Put the code on GitHub (one time)
1. Create a free GitHub account, then a **new public repository** (e.g. `video-playlist`).
   Public repos get free Mac build minutes.
2. Upload everything in this folder, including the hidden `.github` folder.
   Easiest: install Git for Windows, then in this folder run:
       git init
       git add .
       git commit -m "first commit"
       git branch -M main
       git remote add origin https://github.com/YOUR_USERNAME/video-playlist.git
       git push -u origin main

## 2. Get the .ipa
1. On GitHub open the repo's **Actions** tab. The "Build IPA" run starts by itself (3-5 min).
2. If it fails, open the run, click the failed step, and copy the red error lines. Send them to Claude.
3. When it's green, open the run and download **VideoPlaylist-ipa** from "Artifacts".
   Unzip it to get `VideoPlaylist.ipa`.

## 3. Install on the iPhone (Windows)
1. Install **iTunes** and **iCloud** from apple.com (not the Microsoft Store versions; Sideloadly needs the Apple ones).
2. Install **Sideloadly** from sideloadly.io.
3. On the iPhone: Settings > Privacy & Security > **Developer Mode** > On (it restarts the phone).
4. Plug the iPhone into the PC and tap "Trust".
5. In Sideloadly: select your iPhone, drag in `VideoPlaylist.ipa`, enter your Apple ID, click **Start**.
6. On the iPhone: Settings > General > VPN & Device Management > your Apple ID > **Trust**.
7. Open the app.

## 4. Every 7 days (free Apple ID)
Re-run step 3.5 (Sideloadly) to refresh the signature, **installing over the existing app**
(do not delete it first, or you lose your playlists). Alternatively use AltStore for automatic refresh.

## 5. Making changes
Edit the .swift files, `git commit` and `git push`. A new build starts automatically.
