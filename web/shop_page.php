<?php
/**
 * Root delegate for /shop/{id} rewrites on legacy LWS deployments.
 * Forwards to the canonical landing page in /api/.
 */
require __DIR__ . '/api/shop_page.php';
