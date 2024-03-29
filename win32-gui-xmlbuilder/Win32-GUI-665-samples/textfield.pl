use blib;
use Win32::GUI;

my $Window = new Win32::GUI::Window(
    -title  => "Win32::GUI::Textfield test",
    -left   => 100,
    -top    => 100,
    -width  => 300,
    -height => 500,
    -name   => "Window",
#	-style  => WS_MINIMIZEBOX | WS_CAPTION | WS_SYSMENU,
);

$Window->Show();

# $B = new Win32::GUI::Brush(-system => 12);

$Textfield = $Window->AddTextfield(
    -name     => "Textfield",
    -left     => 10,
    -top      => 10,
    -text     => "sample text",
    -width    => 180,
    -height   => 22,
    -foreground => "#000000",
    -background => "#E3E2CC",
);



# print $Window->Textfield->SendMessage(213, 0, 0);

print "Textfield=", $Textfield, "\n";
print "Textfield.handle=$Textfield->{'-handle'}\n";
print "Textfield.keys = ", join(" ", keys(%{$Textfield})), "\n";

printf "Textfield.foreground = %06x\n", $Textfield->{-foreground};


$Window->AddCheckbox(
    -name   => "Password",
    -text   => "Password",
    -left   => 10,
    -top    => 40,
);

# $Window->{Password}->{-background} = $B->{-handle};

my $Readonly = $Window->AddCheckbox(
    -name   => "Readonly",
    -text   => "Read only",
    -left   => 10,
    -top    => 70,
);

$Window->AddButton(
    -name   => "Reset",
    -text   => "Reset",
    -pos    => [  10, 100 ],
);

$Window->AddButton(
    -name   => "ScrollUp",
    -text   => "UP",
    -pos    => [  80, 100 ],
);

$Window->AddButton(
    -name   => "ScrollDown",
    -text   => "DOWN",
    -pos    => [  120, 100 ],
);

$Window->AddButton(
    -name   => "ScrollBottom",
    -text   => "BOTTOM",
    -pos    => [  160, 100 ],
);

$Window->AddButton(
    -name   => "ScrollTop",
    -text   => "TOP",
    -pos    => [  200, 100 ],
);

$Multitext = $Window->AddTextfield(
    -name     => "Multitext",
    -multiline => 1,
    -autohscroll => 1,
    -autovscroll => 1,
	-vscroll   => 1,
	-hscroll   => 1,
    -pos       => [  10, 140 ],
    -size      => [ 180, 180 ],
);


$Multitext->Text("sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text sample text ");

printf "Multitext.style = %x\n", $Multitext->GetWindowLong(-16);

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Password_Click {
    printf "Style before: %8X\n", $Window->Textfield->GetWindowLong(-16);
    print "PasswordChar: ", $Window->Textfield->PasswordChar, "\n";
    if($Window->Textfield->PasswordChar != 0) {
        print "turning Password on...\n";
        $Window->Textfield->Change(-password => 1);
        $Window->Textfield->PasswordChar('*');
    } else {
        print "turning Password off...\n";
        $Window->Textfield->Change(-password => 0);
        $Window->Textfield->PasswordChar(0);

    }
    printf "Style after: %8X\n", $Window->Textfield->GetWindowLong(-16);     
}

sub Readonly_Click {
    printf "Style before: %8X\n", $Window->Textfield->GetWindowLong(-16);
    if($Window->Readonly->Checked()) {
        print "turning Readonly on...\n";
        $Window->Textfield->Change(-readonly => 1);
    } else {
        print "turning Readonly off...\n";
        $Window->Textfield->Change(-readonly => 0);

    }

    $Window->Textfield->Change( -background => [255,0,0] );

    $style = $Window->Textfield->GetWindowLong(-16);
    $style ^= hex('0800');
    $Window->Textfield->SetWindowLong(-16, $style);
    printf "Style after: %8X\n", $Window->Textfield->GetWindowLong(-16);
    $Window->Textfield->InvalidateRect(1);
    $Window->Textfield->Update();

    my($from, $to) = $Window->Textfield->Selection();
    print "Selection: ", substr($Window->Textfield->Text, $from, $to-$from), "\n";

}

sub Reset_Click {
    my $DC = new Win32::GUI::DC($Window->Textfield);
    $rc = $Window->SendMessage(307, $DC, $Window->Textfield->{-handle});
    # $rc = Win32::GUI::SendMessage($Window->{-handle}, hex('133'), 0, 0);
    print "SendMessage.rc = $rc\n";
#    $Window->Textfield->Text("");
	my $C = new Win32::GUI::Cursor("harrow.cur");
	$Window->ChangeCursor($C);
	$Window->Reset->ChangeCursor($C);
}

sub Multitext_Change {
	print "got Change!\n";
	# $Window->Multitext->InvalidateRect(1);
}

sub Textfield_Change {
	print "got Change!\n";
	# $Window->Multitext->InvalidateRect(1);
}

sub ScrollUp_Click {
	$Window->Multitext->Scroll("up");
}
sub ScrollDown_Click {
	$Window->Multitext->Scroll("down");
}
sub ScrollBottom_Click {
	$Window->Multitext->Scroll("bottom");
}
sub ScrollTop_Click {
	$Window->Multitext->Scroll("top");
}
