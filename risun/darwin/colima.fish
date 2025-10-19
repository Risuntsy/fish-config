function colima_start_default
    colima start -p default
end

function colima_stop_default
    colima stop -p default
end

function colima_delete_default
    colima delete -p default
end

function colima_ssh_default
    colima ssh -p default
end

function colima_ssh_rosetta
    colima ssh -p rosetta
end

function colima_start_rosetta
    colima start -p rosetta --arch x86_64 --vm-type vz --vz-rosetta
end

function colima_stop_rosetta
    colima stop -p rosetta
end

function colima_delete_rosetta
    colima delete -p rosetta
end

function colima_status_rosetta
    colima status -p rosetta
end

function colima_status_default
    colima status -p default
end
