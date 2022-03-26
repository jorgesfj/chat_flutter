import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  TextComposer(this.sendMessage);
  final Function({String text, XFile imgFile}) sendMessage;

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _controller = TextEditingController();

  bool _isComposig = false;
  final ImagePicker _picker = ImagePicker();

  void _reset() {
    _controller.clear();
    setState(() {
      _isComposig = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          IconButton(onPressed: () async {
            final XFile? imgFile = await _picker.pickImage(source: ImageSource.camera);

            if(imgFile == null) {
              return;
            }
            widget.sendMessage(imgFile: imgFile);

          }, icon: Icon(Icons.photo_camera)),
          Expanded(
              child: TextField(
            controller: _controller,
            decoration:
                InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
            onChanged: (text) {
              setState(() {
                _isComposig = text.isNotEmpty;
              });
            },
            onSubmitted: (text) {
              widget.sendMessage(text: text);
              _reset();
            },
          )),
          IconButton(onPressed: _isComposig ? () {
            widget.sendMessage(text: _controller.text);
            _reset();
          }: null, icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
