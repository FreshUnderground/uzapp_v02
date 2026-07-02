<?php
/**
 * Sert les fichiers /uploads/ avec le bon Content-Type.
 * Retourne 404 si le fichier n'existe pas (évite de renvoyer index.html du SPA).
 */
$path = isset($_GET['path']) ? $_GET['path'] : '';
$path = ltrim(str_replace('\\', '/', $path), '/');

if ($path === '' || strpos($path, '..') !== false || strpos($path, "\0") !== false) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Invalid path']);
    exit;
}

$baseDir = dirname(__DIR__) . '/uploads/';
$fullPath = $baseDir . $path;

$realBase = realpath($baseDir);
$realFile = realpath($fullPath);

if ($realBase === false || $realFile === false || strpos($realFile, $realBase) !== 0 || !is_file($realFile)) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'File not found']);
    exit;
}

$ext = strtolower(pathinfo($realFile, PATHINFO_EXTENSION));
$mimeMap = [
    'jpg' => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'mp4' => 'video/mp4',
    'webm' => 'video/webm',
    'mov' => 'video/quicktime',
];
$mime = $mimeMap[$ext] ?? null;

if ($mime === null && function_exists('finfo_open')) {
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    if ($finfo) {
        $detected = finfo_file($finfo, $realFile);
        finfo_close($finfo);
        if (is_string($detected) && $detected !== '') {
            $mime = $detected;
        }
    }
}

if ($mime === null) {
    $mime = 'application/octet-stream';
}

header('Content-Type: ' . $mime);
header('Cache-Control: public, max-age=86400');
header('Access-Control-Allow-Origin: *');
header('Content-Length: ' . filesize($realFile));

readfile($realFile);
