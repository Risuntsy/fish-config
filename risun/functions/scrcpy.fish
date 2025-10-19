function scrcpy_local
    adb connect localhost:$argv[1] ; or return $status
    scrcpy -s localhost:$argv[1]
end
