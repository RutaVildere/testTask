
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apikey.dart';

class Giphy{
Future<List<String>> getGifs(String searchQuery, int offset) async{
  var apiUrl='https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=$searchQuery&limit=25&offset=$offset&rating=g&lang=en&bundle=messaging_non_clips';

  try{
    final response=await http.get(Uri.parse(apiUrl));
    if (response.statusCode==200){
      final Map<String, dynamic> data=json.decode(response.body);
      if (data['data']!=null && data['data'].isNotEmpty){
        final List<String> gifUrls=List.generate(
          data['data'].length,
          (index)=>data['data'][index]['images']['fixed_height']['url'],
        );
        return gifUrls;
      } else{
        throw Exception('No GIFs found');
      }
    } else {
      //if no response
      throw Exception('Failed to load GIF');
    } 
  } catch (error){
      throw Exception('Failed to load GIF');
  }
}
}