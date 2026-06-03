<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/health', function () {
    $checks = [
        'database' => checkDatabase(),
        'cache' => checkCache(),
    ];

    $status = collect($checks)->every(fn($v) => $v) ? 'ok' : 'error';
    $code = $status === 'ok' ? 200 : 500;

    return response()->json([
        'status' => $status,
        'checks' => $checks,
        'timestamp' => now()->toISOString(),
    ], $code);
});

function checkDatabase(): bool {
    try {
        DB::connection()->getPdo();
        return true;
    } catch (\Exception $e) {
        return false;
    }
}
