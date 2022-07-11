import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class Card {
  final String title;
  final String img;

  Card(this.title, this.img);
}

class CardResponse {
  final String response;

  CardResponse(this.response);
}

class CardReply {
  final String reply;

  CardReply(this.reply);
}

abstract class CardInterface {
  getCard();

  getCardResponse();

  getCardReply();
}

class ProxyCard extends GetxController implements CardInterface {
  Rx<List<Card>> card = Rx([]);
  Rx<List<CardResponse>> cardResponse = Rx([]);
  Rx<List<CardReply>> cardReply = Rx([]);

  T? getElement<T>(List<T> list, int index) {
    return list.asMap().containsKey(index) ? list.elementAt(index) : null;
  }

  @override
  getCard() {
    card.bindStream(CardStreamPool.cardStream);
  }

  @override
  getCardReply() {
    cardResponse.bindStream(CardStreamPool.cardResponseStream);
  }

  @override
  getCardResponse() {
    cardReply.bindStream(CardStreamPool.cardReplyStream);
  }

  @override
  void onInit() {
    getCard();
    card.listen((p0) {
      if (p0.isNotEmpty) {
        getCardResponse();
        getCardReply();
      }
    });
    super.onInit();
  }
}

class CardStreamPool {
  CardStreamPool._();

  static Stream<List<Card>> get cardStream async* {
    var cardList = await CardRepositories.getCard();
    yield cardList;
  }

  static Stream<List<CardResponse>> get cardResponseStream async* {
    var cardResponseList = await CardRepositories.getResponse();
    yield cardResponseList;
  }

  static Stream<List<CardReply>> get cardReplyStream async* {
    var cardReplyList = await CardRepositories.getReply();
    yield cardReplyList;
  }
}

class CardRepositories {
  CardRepositories._();

  static Future<List<Card>> getCard() async {
    var second = 1;
    await Future.delayed(Duration(seconds: second));
    print('# 카드 정보 로드 완료 $second초');
    return [
      Card('제목1', '이미지1'),
      Card('제목2', '이미지2'),
      Card('제목3', '이미지3'),
      Card('제목4', '이미지4'),
    ];
  }

  static Future<List<CardResponse>> getResponse() async {
    var second = 3;
    await Future.delayed(Duration(seconds: second));
    print('## 응답 정보 로드 완료 $second초');
    return [
      CardResponse('응답1'),
      CardResponse('응답2'),
      CardResponse('응답3'),
      CardResponse('응답4'),
    ];
  }

  static Future<List<CardReply>> getReply() async {
    var second = 4;
    await Future.delayed(Duration(seconds: second));
    print('### 댓글 정보 로드 완료 $second초');
    return [
      CardReply('댓글1'),
      CardReply('댓글2'),
      CardReply('댓글3'),
      CardReply('댓글4'),
    ];
  }
}

class CardBlock implements CardInterface {
  final List<Card> _cardList;
  final List<CardResponse> _cardResponseList;
  final List<CardReply> _cardReplyList;

  CardBlock(this._cardList, this._cardResponseList, this._cardReplyList);

  @override
  getCard() {
    return _cardList;
  }

  @override
  getCardReply() {
    return _cardReplyList;
  }

  @override
  getCardResponse() {
    return _cardResponseList;
  }
}

class CardController extends GetxController {
  Future<CardBlock> getAllInfo() async {
    var cardList = await CardRepositories.getCard();
    var responseList = await CardRepositories.getResponse();
    var replyList = await CardRepositories.getReply();
    return CardBlock(cardList, responseList, replyList);
  }

  Stream<CardBlock> get dataStream async* {
    yield await getAllInfo();
  }

  Rx<CardBlock?> cardBlock = Rx(null);

  @override
  void onInit() async {
    cardBlock.bindStream(dataStream);
    super.onInit();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Get.to(() => const MyHomePage1()),
              child: const Text('기존 방식'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Get.to(() => const MyHomePage2()),
              child: const Text('프록시 방식'),
            ),
          ],
        ),
      ),
    );
  }
}

// 현재 방식 예시
class MyHomePage1 extends StatelessWidget {
  const MyHomePage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CardController());
    return Scaffold(
      body: Obx(
        () {
          var cardBlock = controller.cardBlock.value;
          if (cardBlock == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          var card = cardBlock.getCard();
          var response = cardBlock.getCardResponse();
          var reply = cardBlock.getCardReply();
          return Center(
            child: ListView(
              children: List.generate(
                card.length,
                (index) => ListTile(
                  leading: Text(card[index].img),
                  title: Text(card[index].title),
                  subtitle: Row(
                    children: [
                      Text(response[index].response),
                      const SizedBox(width: 16),
                      Text(reply[index].reply),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 프록시 방식 예시
class MyHomePage2 extends StatelessWidget {
  const MyHomePage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProxyCard());
    return Scaffold(
      body: Obx(
        () {
          var card = controller.card.value;
          var response = controller.cardResponse.value;
          var reply = controller.cardReply.value;

          return Center(
            child: ListView(
              children: List.generate(
                card.length,
                (index) => ListTile(
                  leading: Text(card[index].img),
                  title: Text(card[index].title),
                  subtitle: Row(
                    children: [
                      FadeInObject(
                          text: controller
                                  .getElement<CardResponse>(response, index)
                                  ?.response ??
                              ''),
                      const SizedBox(width: 16),
                      FadeInObject(
                          text: controller
                                  .getElement<CardReply>(reply, index)
                                  ?.reply ??
                              ''),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FadeInObject extends StatefulWidget {
  const FadeInObject({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  State<FadeInObject> createState() => _FadeInObjectState();
}

class _FadeInObjectState extends State<FadeInObject>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation animation;

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animation =
        CurvedAnimation(parent: animationController, curve: Curves.easeInExpo);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isNotEmpty && !animationController.isAnimating) {
      animationController.forward();
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Text(widget.text),
        );
      },
    );
  }
}
