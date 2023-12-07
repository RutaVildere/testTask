// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'giphy.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIF search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GIF searcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final Giphy _giphy=Giphy();

  late StreamController<String> _streamController;
  late Stream<String> _debounce;
  Timer? _searchDebouncer;

  late ScrollController _scrollController;        //Controller for tracking scroll position
  final List<String> _allGifUrls=[];
  int _offset=0;
  bool _loadingMore=false;                //Indicator if more GIFs are being loaded

  @override
  void initState(){
    super.initState();
    _scrollController=ScrollController()..addListener(_scrollListener);
    _streamController=StreamController<String>();
    _debounce=_streamController.stream.debounceTime(const Duration(milliseconds: 300));
    _debounce.listen((String text){
      _searchDebouncer?.cancel();
      _searchDebouncer=Timer(const Duration(milliseconds: 100),() async{
      setState((){
        _allGifUrls.clear();
        _offset=0;
        _loadGifs(text);
      });
      await _loadGifs(text);
      });
    });
    _loadGifs('');
  }

  Future<void> _loadGifs(String searchQuery) async{
    try{
      final List<String> gifs=await _giphy.getGifs(searchQuery, _offset);
      if (_offset==0){                 //If offset=0 then the list is cleared to make sure new Gifs are loaded
        setState((){
          _allGifUrls.clear();
        });
      }
      setState((){
        _allGifUrls.addAll(gifs);
        _offset+=gifs.length;
      });
    } catch (error){
      print('Error: no GIFs found');
    } finally {
      setState(() {
        _loadingMore=false;
      });
    }
  }

  void _scrollListener(){
    if (_scrollController.position.pixels==_scrollController.position.maxScrollExtent && !_loadingMore){
      setState((){              //When the bottom is reached, load more GIFs                
        _loadingMore=true;
      });
      _loadGifs(_controller.text);
    }
  }

  int crossAxisCount(BuildContext context) {        //Display the grid of GIFs depending on the window size
  const double desiredItemWidth = 150.0;
  final double screenWidth = MediaQuery.of(context).size.width;
  final int crossAxisCount = (screenWidth/desiredItemWidth).floor();
  return crossAxisCount;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
          child: Text(widget.title),
          )
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'Insert key words',
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width*0.8,
              child: TextField(
                controller: _controller,
                onChanged: (text){
                  _streamController.add(text);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  hintText:'Type here',
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {                   //Will trigger the state immediately
                setState((){
                  _allGifUrls.clear();
                  _offset=0;
                  _loadGifs(_controller.text);    //Loading GIFs based on the current input
                });
              },
              child: Text('Get GIFs'),
            ),
            SizedBox(height:20),                  //Displaying the GIFs in a grid with vertical scrolling
            Expanded(
              child: GridView.builder(
                gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:crossAxisCount(context),
                  crossAxisSpacing:2.0,
                  mainAxisSpacing:2.0,
                ),
                itemCount:_allGifUrls.length+(_loadingMore? 1:0),
                controller:_scrollController,
                itemBuilder:(context, index) {
                  if (index< _allGifUrls.length) {        //Displaying each GIF individually
                    return Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.network(_allGifUrls[index]),
                    );
                  } else {                       //Loading indicator when more GIFs are being loaded
                    return Center(child:CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _streamController.close();
    super.dispose();
  }
}