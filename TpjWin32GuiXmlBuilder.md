# Building GUIs with Win32::GUI::XMLBuilder, The Perl Journal, November 2004 #

Wouldn't it be nice if there was a simple way to build an interface with forms that allowed a user to do a variety of simple tasks from say a module you've already created; a way one might be able to write solid Win32 GUIs whilst also keeping the visual design separate from the inner workings of your script?

Yes, it would be and that is why I wrote Win32::GUI::XMLBuilder.

In this article I will try to describe how one might build a simple Win32::GUI::XMLBuilder application and also provide a simple template for doing this.
What is it?

Win32::GUI::XMLBuilder (WGX) parses well-formed valid XML containing elements and attributes that help to describe and construct a Win32::GUI object. If you're unfamiliar with what XML is I suggest you read a great introductory tutorial at http://www.w3schools.com/xml/default.asp.

One might use WGX like so: -
```
	use Win32::GUI::XMLBuilder;
	my $gui = Win32::GUI::XMLBuilder->new(*DATA);
	Win32::GUI::Dialog;
	__END__
	<GUI>
	 <Window height='60'>
	  <Button text='Push me!' onClick='sub {$_[0]->Text("Thanks")}'/>
	 </Window>
	</GUI>
```
or equivalently using two files: -
```
	# button.pl
	#
	use Win32::GUI::XMLBuilder;
	my $gui = Win32::GUI::XMLBuilder->new({file=>"button.xml"});
	Win32::GUI::Dialog;

	# button.xml
	#
	<GUI>
	 <Window height='60'>
	  <Button text='Push me!' onClick='sub {$_[0]->Text("Thanks")}'/>
	 </Window>
	</GUI>
```

to produce something like: -

![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/button1.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/button1.png)

that changes to this when pressed.

![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/button2.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/button2.png)

## Installing a Windows File Type handler ##

If you plan to use WGX applications regularly you could add a special file type to Windows Explorer - I personally like to use the extension WGX, and configure the Run action to use the following application: -
```
 "C:\Perl\bin\wperl.exe" -MWin32::GUI::XMLBuilder 

 -e"Win32::GUI::XMLBuilder->new({file=>shift @ARGV});Win32::GUI::Dialog" 
	   "%1" %*
```
That will allow WGX files to be automatically executed by double clicking on them or even by typing them in a Cmd.exe shell.

## Mapping Win32:GUI to Win32::GUI::XMLBuilder ##

If you are familiar with Win32::GUI you probably noticed that Win32::GUI::Dialog is the function that begins the dialog phase for a Win32::GUI object, this is what makes the GUI visible to the user. WGX includes Win32::GUI and all its subclasses. So any function in Win32::GUI is accessible from the code sections of a WGX mark-up file/program.

In fact, WGX might be considered just another way to write Win32::GUI code where Win32::GUI objects become XML elements and Win32::GUI options become XML attributes.

### Win32::GUI Elements ###
```
my $W = new Win32::GUI::Window();
$W->AddButton(...);
```
### Win32::GUI::XMLBuilder Elements ###
```
<Window>
    <Button .../>
</Window>
```

### Win32::GUI Attributes ###
```
..->AddSomeWidget(
  -name => "SW", 
  -text => "Go"
);
```
### Win32::GUI::XMLBuilder Attributes ###
```
<SomeWidget 
  name='SW' 
  text='Go'
/>
```

Elements that will require referencing in your code should be given a name attribute, i.e: -
```
	<Button name='MyButton'/>
```
You can then access this widget internally within your XML as $self->{MyButton}. If you constructed your WGX using something like: -
```
	my $gui = Win32::GUI::XMLBuilder->new(...);
```
Then you can access it as $gui->{MyButton} in your script. If you do not explicitly specify a name one will be created. I try not to use names as far as possible and WGX alongside the NEM events (see below) makes use of various tricks to help you here.

Attributes can contain Perl code or variables and generally any attribute that contains the variable '$self' or starts with 'exec:' will be evaluated. This is useful when one wants to create dynamically sizing windows: -
```
	<GUI>
	 <Window name='W' width='400' height='200'>
	 <StatusBar name='S'
	  text='status text'
	  top='$self->{W}->ScaleHeight-$self->{S}->Height if defined $self->{S}'
	 />
	 </Window>
	</GUI>
```
This shows how to create a simple Window with a StatusBar that automatically positions itself. The value of '$self->{W}->ScaleHeight-$self->{S}->Height if defined $self->{S}' is recalculated every time the user resizes the Window. There is more on auto-resizing later.
Win32::GUI::XMLBuilder has an XML Schema

All WGX XML files will contain this basic structure: -
```
	<GUI>
	 <Window/>
	</GUI>
```
The 

&lt;GUI&gt;

 .. 

&lt;/GUI&gt;

 (or in XML shorthand 

&lt;GUI/&gt;

) elements are required and all WGX elements must be enclosed between these. In fact WGX has a well defined Schema and we should really expand the above to the following XML: -
```
	<?xml version="1.0"?>
	<GUI
	xmlns="http://www.numeninest.com/Perl/WGX"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.numeninest.com/Perl/WGX 
	http://www.numeninest.com/Perl/WGX/win32-gui-xmlbuilder.xsd">
	 <Window/>
	</GUI>
```
I chose not to, allowing me to simplify the code but there is nothing stopping you checking your XML is well-formed and valid using a tool such as Altova's XMLSPY (http://www.altova.com). In fact for large WGX programs it is probably a good idea to check your XML is valid!

## Top Level Widgets ##

Every GUI application must have at least one top level widget. These are the containers of your application. WGX currently supports several including Window, DialogBox and MDIFrame. They differ in behaviour and functionality. For example by default a DialogBox cannot be resized and has no maximize or minimize buttons.

```
<Window width='100' height='50'/> 
```
![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/window.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/window.png)

```
<DialogBox width='100' height='50'/>
```
![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/dialogbox.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/dialogbox.png)
## Event models ##

WGX supports two event models, namely New Event Model (NEM) and Old Event Model (OEM). NEM allows you to add attributes like onClick or onMouseOver containing anonymous subroutines to elements. The first argument to the subroutine is always the object in question. Looking at our example above: -
```
	<Button text='Push me!' onClick='sub {$_[0]->Text("Thanks")}'/>
```
produces a Button widget with the initial text "Push me!", an anonymous sub is called when the user triggers the onClick event. This takes $_[0](0.md) (referring to the same Button) and applies the method "Text" changing the text to "Thanks"._


## Auto-resizing ##

A big headache when writing Win32::GUI applications is managing onResize events. This is normally done by treading through a top level widget's children and explicitly specifying the dimensions that they should have if a Resize event occurs.

WGX will automatically generate an onResize NEM subroutine by reading in the values for top, left, height and width of each child. This will work sufficiently well provided you use values that are dynamic such as $self->{PARENT}->Width, $self->{PARENT}->Height for width, height attributes respectively when creating new widget elements. In fact WGX will assume your child objects will have the same dimensions as their parents and will place them in the top left corner relative to their parent if you do not specify any dimensions explicitly.

In our simple button example, the Button element defaults to the being placed at top 0 and left 0 relative to it's parent Window and having exactly the same width and height of it's parent window. If we wanted to change this default we must specify either left, top, width, height attributes or all these combined and separated with commas in a single dim attribute.

Here two widgets are specified. The Label widget only overrides the height attribute thus taking on spatial defaults for everything else. The Button attribute overrides top and height attributes, the top attribute is necessary to avoid overlapping the Label widget.
```
	<GUI>
	 <Window height='90'>
	  <Label
	   text='Push the button below several times'
	   height='%P%->ScaleHeight/2'
	   align='center'
	  />
	  <Button
	   text='Push me!'
	   top='%P%->ScaleHeight/2'
	   height='%P%->ScaleHeight/2'
	   onClick='sub {
	    $_[0]->Text($_[0]->Text eq "Thanks" ? "Push Me!" : "Thanks")
	   }'
	  />
	 </Window>
	</GUI>
```

### Initial state ###
![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/autoresize-default.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/autoresize-default.png)
### After resize ###
![http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/autoresize-changed.png](http://bsdz-perl.googlecode.com/svn/trunk/win32-gui-xmlbuilder/pod/autoresize-changed.png)

You will have noticed the special value %P% being used in the attributes above. These are substituted by WGX for $self->{PARENT} sparing us the need to name the top level Window widget.

## WGX utility elements ##

A common task when writing an application is building a simple GUI that can recall its last desktop location and maximize or minimize state. One might consider this as not being an integral part of their application and more to do with the interface and design. With WGX one can embed GUI initialization and destruction code directly in the XML file. There are several pure WGX elements that come to aid here.


&lt;WGXPre&gt;

, 

&lt;WGXPost&gt;

 and 

&lt;WGXExec&gt;



These utility elements allow one to execute Perl code before, after and during construction of your GUI. This allows interface specific code to be embedded within your XML document.
```
	<WGXPre></WGXPre>
```
WGXExec and WGXPre elements are executed in place and before GUI construction.

These elements can be useful when one needs to implement something not directly supported by WGX like Toolbars: -
```
	<Toolbar name='TB' height='10'/>
	<WGXExec></WGXExec>
```
Any output returned by WGXExec and WGXPre elements will be parsed as valid XML so: -
```
	<WGXExec></WGXData>
```
and
```
	<Button text='Go'/>
```
are equivalent. If the return data does not contain valid XML then it will make your WGX document invalid - so please do check what these elements return and if you are unsure then add a explicit "return".

WGXPost elements are executed after all GUI elements have been constructed and before your application will start its Win32::GUI::Dialog phase.


&lt;WGXMenu&gt;



This element can be used to create menu systems that can be nested many times more deeply than using the standard Win32::GUI MakeMenu. Although one can use Item elements throughout the structure it is more readable to use the Button attribute when a new nest begins, i.e.
```
	<WGXMenu name="M">
	 <Button name='File' text='&File'>
	  <Button text='New'>
	   <Item text='Type One Document'/>
	   ...
	  </Button>
	  <Item name='ExitPrompt' 
	   text='Prompt on Exit'
	   checked='exec:$registry->{exitprompt}'
	   onClick='sub { 
		  $self->{ExitPrompt}->Checked(not $self->{ExitPrompt}->Checked); 
		 }'
	  />
	  <Item text='Exit' onClick='sub { Exit($_[0]) }'/>
	 </Button>
	 <Button name='Help' text='&Help'>
	  <Item text='Contents'/>
	  <Item separator='1'/>
	  <Item text='About' onClick='sub {
	   Win32::GUI::MessageBox(
	    $_[0],
	    "... some info.",
	    "About ...",
	    MB_OK|MB_ICONASTERISK
	   );
	  }'/>
	 </Button>
	</WGXMenu>
```
You can see that separator lines can be specified by setting the separator attribute to 1. You will also notice menu items can also contain check boxes and in the example above the check box state is stored in the registry.
Example Listing

We have looked at various aspects of Win32::GUI::XMLBuilder module and I hope I have given you a good base to start developing your own applications. I have provided a complete example with this article. It is the application template also available with the distribution and should be a good starting point for any Win32 application.

Reprinted courtesy of The Perl Journal (http://www.tpj.com/).