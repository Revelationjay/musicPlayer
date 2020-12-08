import 'package:dio/dio.dart';
import 'package:musicPlayer/models/exception.dart';
import 'package:musicPlayer/services/secrets.dart';

class SongInfo {
  static Future<Map<String, String>> getSongInfo(
      String songTitle, String songArtist) async {
    Dio dio = Dio();
    Map<String, String> info = Map();
    var url = 'https://rapidapi.p.rapidapi.com/search';
    // song titile that start with e.g '14. blabla' dont get any result

    if (songTitle.startsWith(RegExp(r'\d{1,2}\. '))) {
      print('dot guy');
      songTitle = songTitle.split(RegExp(r'\d{1,2}\. ')).last;
      print(songTitle);
      // return {};
    }
    if (songArtist.toLowerCase().contains('unknown artist')) {
      throw CustomException('Artist name is required');
    }
    try {
      var response = await dio.get(
        url,
        queryParameters: {'q': '$songArtist $songTitle'},
        options: Options(
          method: 'GET',
          headers: {
            "x-rapidapi-key": kApiKey,
            "x-rapidapi-host": "deezerdevs-deezer.p.rapidapi.com"
          },
        ),
      );
      if (response.statusCode == 429) {
        throw CustomException('Too many request, try again later');
      }
      if (response.data['total'] == 0) {
        print('empty');
        print(response.statusCode);
        print(response.data);
        throw CustomException('Info not available');
      }
      // print(response.data[0]);
      info['title'] = response.data['data'][0]['title'];
      info['artist'] = response.data['data'][0]['artist']['name'];
      int albumId = response.data['data'][0]['album']['id'];
      url = 'https://rapidapi.p.rapidapi.com/album/$albumId';
      response = await dio.get(
        url,
        options: Options(
          method: 'GET',
          headers: {
            "x-rapidapi-key": kApiKey,
            "x-rapidapi-host": "deezerdevs-deezer.p.rapidapi.com"
          },
        ),
      );
      if (response.data == null) {
        print('empty album info');
        print(response.statusCode);
        print(response.data);
        throw CustomException('Info not available, try again later');
      }
      info['album'] = response.data['title'];
      info['genre'] = response.data['genres']['data'][0]['name'];
      info['year'] = response.data['release_date'];
    } on CustomException catch (err) {
      throw err;
    } on DioError catch (err) {
      print(err);
      if (err.message.contains('Failed host lookup')) {
        throw CustomException('Please check your network and try again');
      }
      throw CustomException('Something went wrong, try again later');
    } catch (err) {
      print(err);
      throw CustomException('Something went wrong, try again later');
    }
    return info;
  }
}
