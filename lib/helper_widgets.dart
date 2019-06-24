import 'package:flutter/material.dart';

class ImageHistoryFAB extends StatelessWidget {
  const ImageHistoryFAB({
    this.onTap,
    this.onLongPress,
    Key key,
  }) : super(key: key);

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.black,
        elevation: 2,
        shape: const CircleBorder(),
        child: Container(
          height: 40,
          width: 40,
          child: Stack(
            alignment: const Alignment(-0.1, 0),
            children: <Widget>[
              const Icon(
                Icons.history,
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                onLongPress: onLongPress,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ImageHistoryListItem extends StatelessWidget {
  const ImageHistoryListItem({
    Key key,
    this.leading,
    this.image,
    this.trailingButton,
    this.deleteButton,
  }) : super(key: key);

  final Widget leading;
  final Image image;
  final Widget trailingButton;
  final Widget deleteButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        Spacer(),
        image,
        Spacer(),
        Container(
          width: 60,
          child: deleteButton,
        ),
        Container(
          width: 60,
          child: trailingButton,
        ),
      ],
    );
  }
}

class ImageHistoryListButton extends StatelessWidget {
  const ImageHistoryListButton({
    Key key,
    this.onPressed,
    this.child,
  }) : super(key: key);

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      padding: const EdgeInsets.all(0),
      onPressed: onPressed,
      child: child,
    );
  }
}
