import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:weather_app/widgets/location_widget.dart';
import 'package:weather_app/services/debouncer.dart';
import 'package:http/http.dart' as http;

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // initialize variables and constants

  // debouncer to debounce input and search
  final _debouncer = Debouncer(milliseconds: 500);
  bool isSearchActive = false;
  // suggestions list
  List<Widget> suggestions = [];

  // api keys to fetch data
  String PLACES_API_KEY = "";
  String GEOCODE_API_KEY = "";
  String suggestText = "No suggestions yet";
  final TextEditingController _search = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  isSearchActive = !isSearchActive;
                }),
                child: TextField(
                  onChanged: (value) {
                    if (value == "") {
                      // if value is empty no need to search
                      setState(() {
                        suggestText = "No suggestions yet";
                        suggestions = [];
                      });
                      return;
                    }
                    // set text to loading while data is being fetched
                    setState(() => suggestText = "Loading suggestions...");

                    _debouncer.run(() {
                      http
                          .get(Uri.parse(
                              "http://api.positionstack.com/v1/forward?access_key=$GEOCODE_API_KEY&query=$value"))
                          .then((res) {
                        var jsonResp = jsonDecode(res.body);
                        // if error return
                        if (jsonResp.containsKey('error')) {
                          return;
                        }
                        List<Widget> suggest = [];
                        for (final elem in jsonResp['data']) {
                          suggest.add(
                            Location(
                              latitude: elem['latitude'],
                              longitude: elem['longitude'],
                              label: elem['label'].length > 25
                                  ? elem['label'].substring(0, 25)
                                  : elem['label'],
                            ),
                          );
                        }
                        // show maximum 8 suggestions
                        if (suggest.length > 8) {
                          suggest = suggest.sublist(0, 8);
                        }
                        // set variables accordingly
                        setState(() {
                          suggestions = suggest;
                          suggestText = "No suggestions yet";
                        });
                      });
                    });
                  },
                  controller: _search,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(15),
                    hintText: "Search any place",
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: isSearchActive
                            ? const Color.fromRGBO(36, 96, 155, 1)
                            : Colors.grey.withOpacity(0.02),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              suggestions.isEmpty
                  ? Text(
                      suggestText,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: ListView(
                        physics:
                            const BouncingScrollPhysics(), // to avoid blue tint when scrolled more
                        children: suggestions,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
