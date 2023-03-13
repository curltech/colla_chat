import 'package:openai_dalle_wrapper/network/network.dart';

///提供Dall-e2图像生成的功能
class DalleImage {
  late final OpenaiDalleWrapper openAI;

  DalleImage(String apiKey) {
    openAI = OpenaiDalleWrapper(
      apiKey: apiKey,
    );
  }

  Future<String> generateImage(String text) async {
    final imagePath = await openAI.generateImage(text);
    return imagePath;
  }

  Future<List<dynamic>> editImage(
    String imagePath,
    String text,
    int numberOfVariations,
  ) async {
    final generatedImages =
        await openAI.editImage(imagePath, text, numberOfVariations);

    return generatedImages;
  }
}
