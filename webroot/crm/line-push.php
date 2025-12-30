<?php
// 允許跨網域呼叫
// === CORS 必備設定 ===
// 允許任何來源連線
header("Access-Control-Allow-Origin: *");
// 允許的請求方法
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
// 允許的 Header
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// --- 關鍵：直接攔截並處理 OPTIONS 預檢請求 ---
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    // 告訴瀏覽器：「我可以接受跨網域，請放行」
    http_response_code(200);
    exit; // 直接結束，不要執行下面的發送邏輯
}
// === CORS 設定結束 ===

// 1. 設定變數 (請替換成您剛剛取得的資料)
$channelAccessToken = "f45e9aaa6b28b3e997738909d426eca9";
$userId = "U39be15887c5b98b3bf8b276861290e10"; 

// 2. 接收前端 Vue 傳來的訊息
$data = json_decode(file_get_contents("php://input"), true);
$textMessage = isset($data['message']) ? $data['message'] : '無內容';

if (empty($textMessage)) {
    echo json_encode(["status" => "error", "msg" => "No message"]);
    exit;
}

// 3. 準備發送給 Line 的資料結構
$payload = [
    'to' => $userId, // 發給誰
    'messages' => [
        [
            'type' => 'text',
            'text' => $textMessage // 訊息內容
        ]
    ]
];

// 4. 使用 cURL 發送 POST 請求
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://api.line.me/v2/bot/message/push');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $channelAccessToken
]);

$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// 5. 回傳結果
echo json_encode(["status" => "sent", "http_code" => $httpCode, "result" => $result]);
?>