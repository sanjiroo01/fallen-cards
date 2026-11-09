extends SceneTree
## Scrive accanto al gioco esportato la cartella LICENZE: crediti, licenza di Godot e delle sue librerie,
## licenze dei caratteri e degli shader. Uso (dalla cartella GamePC):
##   godot --headless --path . --script tools/licenze.gd -- ../build/LICENZE

const MIT := """Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "../build/LICENZE"
	DirAccess.make_dir_recursive_absolute(out)
	_copy("res://CREDITI.txt", out + "/CREDITI.txt")
	for f in ["OFL-Cinzel.txt", "OFL-CinzelDecorative.txt", "OFL-IMFell.txt", "OFL-EBGaramond.txt"]:
		_copy("res://fonts/" + f, out + "/" + f)
	_write(out + "/Godot_LICENSE.txt", Engine.get_license_text())
	var t := "Componenti di terze parti incluse in Godot Engine e loro licenze.\n\n"
	for part in Engine.get_copyright_info():
		t += "== %s\n" % part["name"]
		for piece in part["parts"]:
			for c in piece["copyright"]:
				t += "   Copyright %s\n" % c
			t += "   Licenza: %s\n" % piece["license"]
		t += "\n"
	var lic := Engine.get_license_info()
	for k in lic:
		t += "\n==================== %s ====================\n%s\n" % [k, lic[k]]
	_write(out + "/Godot_terze_parti.txt", t)
	_write(out + "/Shader_MIT.txt", "Hash without Sine\nCopyright (c) 2014 David Hoskins.\n\n" + MIT
			+ "\n\nFunzioni di rumore\nCopyright (c) Inigo Quilez.\n\n" + MIT)
	print("LICENZE scritte in ", out)
	quit()


func _copy(src: String, dst: String) -> void:
	_write(dst, FileAccess.get_file_as_string(src))


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
