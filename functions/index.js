const { onCall } = require("firebase-functions/v2/https");
const OpenAI = require("openai");

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

exports.analyzeFoodImage = onCall(async (request) => {
  const imageBase64 = request.data.imageBase64;

  if (!imageBase64) {
    throw new Error("imageBase64 is required");
  }

  const response = await openai.responses.create({
    model: "gpt-4.1-mini",
    input: [
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text:
              "이 이미지를 보고 냉장고에 등록할 식품 정보를 JSON으로만 반환해줘. " +
              "형식은 {\"itemName\":\"\",\"expireDate\":\"YYYY.MM.DD 또는 미확인\",\"storageType\":\"IN_CONTAINER\",\"recommendedStorageDays\":7} 로 해줘.",
          },
          {
            type: "input_image",
            image_url: `data:image/jpeg;base64,${imageBase64}`,
          },
        ],
      },
    ],
  });

  try {
    return JSON.parse(response.output_text);
  } catch (e) {
    return {
      itemName: "알 수 없음",
      expireDate: "미확인",
      storageType: "IN_CONTAINER",
      recommendedStorageDays: 7,
    };
  }
});