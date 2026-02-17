function maa_arknights_daily_dockur
    docker-compose -f ~/App/redroid/arknights_auto/docker-compose.yaml up -d

    sleep 5

    adb connect localhost:5555
    maa update
    _awake_run maa -v run -p 5555 daily

    docker-compose -f ~/App/redroid/arknights_auto/docker-compose.yaml down
end

function maa_arknights_daily_bluestacks
    _awake_run maa run -p bluestacks -v daily
end

function maa_arknights_rouge_jie_garden_bluestacks
    _awake_run maa run -p bluestacks -v rouge_jie_garden
end

function maa_arknights_rouge_sami_bluestacks
    _awake_run maa run -p bluestacks -v rouge_sami
end

function maa_arknights_rouge_jie_garden_x5m2
    set -l device_sn QV72130554

    adb -s $device_sn shell settings put global stay_on_while_plugged_in 7; or return $status
    adb -s $device_sn shell input keyevent KEYCODE_WAKEUP; or return $status

    maa update; or return $status
    _awake_run maa run -p x5m2 -v rouge_jie_garden

    adb -s $device_sn shell am force-stop com.hypergryph.arknights; or return $status
    adb -s $device_sn shell settings put global stay_on_while_plugged_in 0; or return $status
end

function maa_arknights_rouge_sami_x5m2
    set -l device_sn QV72130554

    adb -s $device_sn shell settings put global stay_on_while_plugged_in 7; or return $status
    adb -s $device_sn shell input keyevent KEYCODE_WAKEUP; or return $status

    maa update; or return $status
    _awake_run maa run -p x5m2 -v rouge_sami

    maa_arknights_shutdown_x5m2; or return $status
end


function maa_arknights_rouge_phantom_x5m2
    set -l device_sn QV72130554

    adb -s $device_sn shell settings put global stay_on_while_plugged_in 7; or return $status
    adb -s $device_sn shell input keyevent KEYCODE_WAKEUP; or return $status

    maa update; or return $status
    _awake_run maa run -p x5m2 -v rouge_phantom
    maa_arknights_shutdown_x5m2; or return $status
end

function maa_arknights_shutdown_x5m2
    set -l device_sn QV72130554
    adb -s $device_sn shell am force-stop com.hypergryph.arknights; or return $status
    adb -s $device_sn shell settings put global stay_on_while_plugged_in 0; or return $status
end

function maa_arknights_daily_x5m2
    set -l date_str (date +%Y-%m-%d)
    set -l save_screenshot_dir ~/Pictures/maa/(date +%y%m)
    set -l screenshot_file_path "$save_screenshot_dir/{$date_str}.png"
    set -l device_screenshot "/sdcard/{$date_str}_daily.png"
    set -l device_sn QV72130554

    adb -s $device_sn shell settings put global stay_on_while_plugged_in 7; or return $status
    adb -s $device_sn shell input keyevent KEYCODE_WAKEUP; or return $status

    if not _is_nixos
        maa update; or return $status
    end
    _awake_run maa run -p x5m2 -v daily

    if test $status -eq 0
        mkdir -p "$save_screenshot_dir"; or return $status
        adb -s $device_sn shell screencap $device_screenshot; or return $status
        adb -s $device_sn pull $device_screenshot "$screenshot_file_path"; or return $status
        adb -s $device_sn shell rm -f $device_screenshot

        _open $screenshot_file_path; or return $status
    end

    maa_arknights_shutdown_x5m2; or return $status
end


function maa_arknights_daily_waydroid
    set -l date_str (date +%Y-%m-%d)
    set -l save_screenshot_dir ~/Pictures/maa/(date +%y%m)
    set -l screenshot_file_path "$save_screenshot_dir/{$date_str}.png"
    set -l device_screenshot "/sdcard/{$date_str}_daily.png"
    set -l device_sn 192.168.240.112

    if not _is_nixos
        maa update; or return $status
    end
    _awake_run maa run -p waydroid -v daily

    if test $status -eq 0
        mkdir -p "$save_screenshot_dir"; or return $status
        adb -s $device_sn shell screencap $device_screenshot; or return $status
        adb -s $device_sn pull $device_screenshot "$screenshot_file_path"; or return $status
        adb -s $device_sn shell rm -f $device_screenshot

        _open $screenshot_file_path; or return $status
    end
end

function maa_arknights_start_x5m2
    set -l device_sn QV72130554

    adb -s $device_sn shell settings put global stay_on_while_plugged_in 7; or return $status
    adb -s $device_sn shell input keyevent KEYCODE_WAKEUP; or return $status
end
