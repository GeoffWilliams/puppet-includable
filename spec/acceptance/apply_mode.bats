@test "includable returns true when class is includable" {
    grep 'class exists' /tmp/class_exists.txt
}

@test "includable returns false when class is not includable" {
    grep 'class missing' /tmp/class_missing.txt
}

@test "class was not accidentally evaluated" {
    ! ls /tmp/mock_class_evaluated.txt
}