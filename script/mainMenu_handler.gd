extends CanvasLayer

signal main_menu_opened

@onready var main_menu_container = Control.new() # Container für das Hauptmenü
@onready var main_menu_button = Button.new()
@onready var resume_button = Button.new()
@onready var settings_button = Button.new()
@onready var quit_button = Button.new()

func _ready():
	# Hauptmenü Container konfigurieren
	main_menu_container.name = "MainMenu"
	main_menu_container.size_flags_horizontal = Control.SIZE_EXPAND
	main_menu_container.size_flags_vertical = Control.SIZE_EXPAND
	main_menu_container.visible = false
	add_child(main_menu_container)

	# Hauptmenü Button in der Spielwelt
	main_menu_button.text = "Hauptmenü"
	add_child(main_menu_button)
	main_menu_button.connect("pressed", _on_main_menu_button_pressed)
	# Positioniere den Button nach Bedarf (Beispiel: oben links)
	main_menu_button.position = Vector2(10, 10)

	# Buttons für das Hauptmenü
	resume_button.text = "Fortsetzen"
	settings_button.text = "Einstellungen"
	quit_button.text = "Beenden"

	# Füge Buttons zum Container hinzu
	main_menu_container.add_child(resume_button)
	main_menu_container.add_child(settings_button)
	main_menu_container.add_child(quit_button)

	# Verbinde Signale der Hauptmenü-Buttons
	resume_button.connect("pressed", _on_resume_button_pressed)
	settings_button.connect("pressed", _on_settings_button_pressed)
	quit_button.connect("pressed", _on_quit_button_pressed)

	# Layout für die Hauptmenü-Buttons (Beispiel: vertikal zentriert)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_menu_container.add_child(vbox)
	vbox.add_child(resume_button)
	vbox.add_child(settings_button)
	vbox.add_child(quit_button)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_main_menu()

func _on_main_menu_button_pressed():
	toggle_main_menu()

func toggle_main_menu():
	main_menu_container.visible = not main_menu_container.visible
	if main_menu_container.visible:
		emit_signal("main_menu_opened")

func _on_resume_button_pressed():
	toggle_main_menu()
	# Hier Logik zum Fortsetzen des Spiels einfügen

func _on_settings_button_pressed():
	# Hier Logik zum Öffnen der Einstellungen einfügen
	print("Einstellungen geöffnet")

func _on_quit_button_pressed():
	get_tree().quit()
