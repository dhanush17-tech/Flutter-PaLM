import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a blue toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.

          ),
      home: ChatbotPage(),
    );
  }
}

class ChatbotPage extends StatelessWidget {
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final messages = snapshot.data?.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages?.length,
                  itemBuilder: (context, index) {
                    final message = messages![index];
                    final bool isUserMessage =
                        message['isUserMessage'] ?? false;
                    final response = message['response'];
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            message['prompt'],
                            style: TextStyle(
                              fontWeight:
                                  isUserMessage ? FontWeight.bold : null,
                            ),
                          ),
                          tileColor: isUserMessage
                              ? Colors.green[100]
                              : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        StreamBuilder(
                          stream: _firestore
                              .collection("messages")
                              .doc(snapshot.data!.docs[index].id)
                              .snapshots(),
                          builder: (context, s) {
                            if (s.hasError) {
                              return Text('Error: ${s.error}');
                            }

                            if (!s.hasData || s.data?.data() == null) {
                              return Container();
                            }

                            final responseData = s.data?.data();
                            final responseText =
                                responseData?['response'] ?? '';

                            return ListTile(
                              title: Text(
                                responseText,
                                style: TextStyle(
                                  fontWeight:
                                      isUserMessage ? FontWeight.bold : null,
                                ),
                              ),
                              tileColor: isUserMessage
                                  ? Colors.green[100]
                                  : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            );
                          },
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[300],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(context),
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    String message = _textEditingController.text.trim();
    if (message.isNotEmpty) {
      _textEditingController.clear();
      await _firestore.collection('messages').add({
        'prompt': message,
        'isUserMessage': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
