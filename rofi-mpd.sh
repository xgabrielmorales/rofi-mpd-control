#!/usr/bin/bash
# [MPD CONFIG]
PORT=6600;

# [ROFI CONFIG]
ROFI="rofi -i -dmenu -p ";
ROFI_THEME="-theme ~/.config/rofi/mpd.rasi";
ROFI_MENU="rofi -i $ROFI_THEME -dmenu -p Library";

play_song() {
	TITLE=$1;
	ALBUM_NAME=$2;
	ARTIST_NAME=$3;

	if [[ "$ARTIST_NAME" = "" && "$ALBUM_NAME" = "" ]]; then
		SONG_PATH=$(mpc --port $PORT find Title "$TITLE");
	elif [ "$AlbumArtist" = "" ]; then
		SONG_PATH=$(mpc --port $PORT find Album "$ALBUM_NAME" Title "$TITLE");
	else
		SONG_PATH=$(mpc --port $PORT find AlbumArtist "$ARTIST_NAME" Album "$ALBUM_NAME" Title "$TITLE");
	fi

	# If the playlist is empty, just add the song and play it
	if [ "$(mpc --port $PORT playlist | wc -l)" = "0" ]; then
		mpc --port $PORT add "$SONG_PATH";
		mpc --port $PORT play;

	# If there is at least one song in the playlist, add it in front of it and play it.
	else
		CURRENT_POSITION=$(mpc --port $PORT status | sed -n '2{p;q}' | awk '{print $2}' | sed -E 's/(#|\/.*)//g');
		END_POSITIONITION=$(mpc --port $PORT playlist | wc -l);

		mpc --port $PORT add "$SONG_PATH";
		mpc --port $PORT move $(($END_POSITIONITION+1)) $(($CURRENT_POSITION+1));
		mpc --port $PORT play $(($CURRENT_POSITION+1));
	fi
}

play_playlist() {
	PLAYLIST_NAME=$1

	mpc --port $PORT clear
	mpc --port $PORT load "$PLAYLIST"
	mpc --port $PORT play

}

list_by_playlist() {
	PLAYLIST=$(mpc --port $PORT lsplaylist | $ROFI);

	if [ "$PLAYLIST" = "" ]; then
		exit;
	fi

	play_playlist
}

list_all_songs() {
	TITLE=$(mpc --port $PORT list title | $ROFI);

	if [ "$TITLE" = "" ]; then
		exit;
	fi

	echo $TITLE
	play_song "$TITLE";
}

list_album_titles() {
	ALBUM_NAME=$1;
	ARTIST_NAME=$2;

	if [[ "$ARTIST_NAME" = "" && "$ALBUM_NAME" = "" ]]; then
		exit;
	elif [[ "$ARTIST_NAME" = "" ]]; then
		TITLE=$(mpc --port "$PORT" --format %title% find Album "$ALBUM_NAME" | $ROFI);
	else
		TITLE=$(mpc --port "$PORT" --format %title% find AlbumArtist "$ARTIST_NAME" Album "$ALBUM_NAME" | $ROFI);
	fi

	if [ "$TITLE" = "" ]; then
		exit;
	fi

	play_song "$TITLE" "$ALBUM_NAME" "$ARTIST_NAME";
}

list_by_album() {
	ARTIST_NAME=$1;

	if [ "$ARTIST_NAME" = "" ]; then
		ALBUM_NAME=$(mpc --port $PORT list Album | $ROFI);
	else
		ALBUM_NAME=$(mpc --port $PORT list album AlbumArtist "$ARTIST_NAME" | $ROFI);
	fi

	if [ "$ALBUM_NAME" = "" ]; then
		exit
	fi

	OPTIONS=$(printf '%s\n%s\n%s\n%s' \
		"Listen to the album"         \
		"Listen to a track"           \
		"Add album to playlist"       \
		"Add a track to the playlist" \
		| $ROFI_MENU);

	if [ "$OPTIONS" = "Listen to the album" ]; then
		mpc --port $PORT clear

		if [ "$ARTIST_NAME" = "" ]; then
			mpc --port $PORT find Album "$ALBUM_NAME" | mpc --port $PORT add
		else
			mpc --port $PORT find AlbumArtist "$ARTIST_NAME" Album "$ALBUM_NAME" | mpc --port $PORT add
		fi

		mpc --port $PORT play
	elif [ "$OPTIONS" = "Listen to a track" ]; then
		list_album_titles "$ALBUM_NAME" "$ARTIST_NAME";
	elif [ "$OPTIONS" = "Add album to playlist" ]; then
		if [ "$ARTIST_NAME" = "" ]; then
			mpc --port $PORT find Album "$ALBUM_NAME" | mpc --port $PORT add | mpc --port $PORT add
		else
			mpc --port $PORT find AlbumArtist "$ARTIST_NAME" Album "$ALBUM_NAME" | mpc --port $PORT add
		fi
	elif [ "$OPTIONS" = "Add a track to the playlist" ]; then
		echo "Entro?"
		notify-send "Esta función aun no está disponible";
	else
		exit;
	fi
}

list_by_album_artist() {
	ARTIST_NAME="$(mpc --port $PORT list AlbumArtist | $ROFI)";

	if [ "$ARTIST_NAME" = "" ]; then
		exit;
	fi

	list_by_album "$ARTIST_NAME";
}

case $1 in
	*)
		MENU=$(printf "%s\n%s\n%s\n%s\n" \
			"All Songs"                  \
			"Album Aritst"               \
			"Album"                      \
			"Playlist"                   \
			| $ROFI_MENU);

		if [ "$MENU" = "Album Aritst" ]; then
			list_by_album_artist;
		elif [ "$MENU" = "Album" ]; then
			list_by_album;
		elif [ "$MENU" = "All Songs" ]; then
			list_all_songs;
		elif [ "$MENU" = "Playlist" ]; then
			list_by_playlist;
		fi
	;;
esac
