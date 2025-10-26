// Feather disable all

#macro MSDF_DOWNSCALE            (1/2)
#macro MSDF_DPI_GM_TO_NORMATIVE  (4/3)
#macro MSDF_DPI_NORMATIVE_TO_GM  (3/4)
#macro MSDF_ATLAS_FIX  1
#macro MSDF_ATLAS_TRIM  0

function MsdfUpdateFonts()
{
    var _time = get_timer();
    
    __MsdfTrace("Calling `MsdfUpdateFonts()`");
    
    var _warnings = 0;
    var _zeroSubstring = ["0"];
    var _batchFilePath = game_save_id + "run.bat";
    
    var _projectDirectory = filename_dir(GM_project_filename) + "/";
    var _fontsDirectory   = _projectDirectory + "fonts/";
    var _msdfGenDirectory = _projectDirectory + "msdf-atlas-gen/";
    var _msdfGenExe       = "msdf-atlas-gen.exe";
    var _exePath          = _msdfGenDirectory + _msdfGenExe;
    var _imageOutPath     = _msdfGenDirectory + "__image.png";
    var _jsonOutPath      = _msdfGenDirectory + "__json.json";
    
    //Check configuration
    if (os_type != os_windows)
    {
        __MsdfError("MSDF generation only works on Windows.\n(Though MSDF rendering at runtime works on every platform.)");
    }
    
    if (not extension_exists("execute_shell_simple_ext"))
    {
        __MsdfError("Add YellowAfterlife's \"execute_shell_simple\" extension to proceed.\nThis can be found at https://yellowafterlife.itch.io/gamemaker-execute-shell-simple\nPlease also consider making a donation to him.");
    }
    
    if (GM_is_sandboxed)
    {
        __MsdfError("Please disable file system sandbox for the Windows platform before running `MsdfUpdateFonts()`.\nYou can turn it back on again afterwards.");
    }
    
    var _sacrificialFont = asset_get_index("__MsdfSacrificialAsset");
    if (not font_exists(_sacrificialFont))
    {
        __MsdfError("Please disable \"Automatically remove unused assets when compiling\" before running `MsdfUpdateFonts()`.\nYou can turn it back on again afterwards.");
    }
    
    //Report which fonts we're going to be processing
    var _fontArray = asset_get_ids(asset_font);
    var _msdfFontArray = tag_get_asset_ids("msdf", asset_font);
    
    var _i = 0;
    repeat(array_length(_fontArray))
    {
        var _font = _fontArray[_i];
        var _fontName = font_get_name(_font);
        
        if (string_copy(_fontName, 1, 9) == "__newfont")
        {
            __MsdfTrace($"Font \"{font_get_name(_font)}\" ({_font}) was added at runtime and will be ignored");
        }
        else if (font_get_sdf_enabled(_font)) //We're not worried about SDF fonts
        {
            __MsdfTrace($"Font \"{font_get_name(_font)}\" ({_font}) is an SDF font and will be ignored");
        }
        else
        {
            __MsdfTrace($"Font \"{font_get_name(_font)}\" ({_font}) will be converted");
        }
        
        ++_i;
    }
    
    //Clean up any resources that are left on disk after last time
    var _batchPreexisting = false;
    if (file_exists(_batchFilePath))
    {
        __MsdfTrace($"Cleaning up batch file from previous attempts");
        __MsdfTrace($"This may indicate an error occurred last time; inserting `pause` command for debugging this time round");
        file_delete(_batchFilePath);
        
        _batchPreexisting = true;
    }
    
    if (file_exists(_imageOutPath))
    {
        __MsdfTrace($"Cleaning up image from previous attempts");
        file_delete(_imageOutPath);
    }
    
    if (file_exists(_jsonOutPath))
    {
        __MsdfTrace($"Cleaning up JSON from previous attempts");
        file_delete(_jsonOutPath);
    }
    
    //Create some reusable buffers
    var _stringBuffer = buffer_create(1024, buffer_grow, 1);
    var _batchBuffer = buffer_create(1024, buffer_grow, 1);
    
    //Start converting fonts...
    var _i = 0;
    repeat(array_length(_msdfFontArray))
    {
        __MsdfTrace($"Converting font \"{font_get_name(_font)}\" to Msdf");
        
        var _font = _msdfFontArray[_i];
        var _fontName = font_get_name(_font);
        var _fontInfo = font_get_info(_font);
        
        var _fontPointSize = _fontInfo.size;
        __MsdfTrace($"GameMaker point size is {_fontPointSize}");
        
        var _writePointSize = MSDF_DOWNSCALE*MSDF_DPI_GM_TO_NORMATIVE*_fontPointSize;
        __MsdfTrace($"Equivalent normative point size is {_writePointSize}");
        
        var _fontOriginName = _fontInfo.name;
        __MsdfTrace($"Font name is \"{_fontOriginName}\"");
        
        var _cleanFontOriginName = filename_name(_fontOriginName);
        var _ttfPath = $"{_msdfGenDirectory}{_cleanFontOriginName}.ttf";
        if (not file_exists(_ttfPath))
        {
            __MsdfTrace($"Could not find .ttf at \"{_ttfPath}\"");
            
            _ttfPath = $"{_msdfGenDirectory}{string_lower(_cleanFontOriginName)}.ttf";
            if (not file_exists(_ttfPath))
            {
                __MsdfTrace($"Could not find .ttf at \"{_ttfPath}\"");
                _ttfPath = $"{_msdfGenDirectory}{string_upper(_cleanFontOriginName)}.ttf";
            
                if (not file_exists(_ttfPath))
                {
                    __MsdfError($"Could not find .ttf in \"{_msdfGenDirectory}\". Looked for:\n- {_ttfPath}\n- {string_lower(_ttfPath)}\n- {string_upper(_ttfPath)}");
                }
            }
        }
        
        __MsdfTrace($"Found .ttf at \"{_ttfPath}\"");
        
        var _fontDirectory = $"{_fontsDirectory}{_fontName}/";
        var _yyPath = $"{_fontDirectory}{_fontName}.yy";
        __MsdfTrace($"Looking for .yy at \"{_yyPath}\"");
        
        if (not file_exists(_yyPath))
        {
            __MsdfError($"Expected .yy file not found at \"{_yyPath}\"");
        }
        
        var _yyBuffer = buffer_load(_yyPath);
        if (_yyBuffer < 0)
        {
            __MsdfError($"Failed to load \"{_yyPath}\"");
        }
        
        __MsdfTrace($".yy size is {buffer_get_size(_yyBuffer)} bytes");
        
        var _yyString = buffer_read(_yyBuffer, buffer_text);
        buffer_delete(_yyBuffer);
        
        try
        {
            var _yyJSON = json_parse(_yyString);
        }
        catch(_error)
        {
            __MsdfError($"Failed to parse JSON found in \"{_yyPath}\"");
        }
        
        var _fontSdfSpread = _yyJSON.sdfSpread;
        __MsdfTrace($"GameMaker SDF spread is {_fontSdfSpread}");
        
        var _writePxRange = MSDF_DOWNSCALE*MSDF_DPI_GM_TO_NORMATIVE*_fontSdfSpread;
        _writePxRange /= 2; //GM also uses an SDF spread that's 2x too big
        __MsdfTrace($"Equivalent normative MSDF spread (after downscaling) is {_writePxRange}");
        
        buffer_seek(_stringBuffer, buffer_seek_start, 0);
        
        var _glyphsDict = _fontInfo.glyphs;
        var _glyphArray = struct_get_names(_glyphsDict);
        __MsdfTrace($"Found {array_length(_glyphArray)} glyphs, building hexcode arguments");
        
        var _i = 0;
        repeat(array_length(_glyphArray))
        {
            var _glyphChar = _glyphArray[_i];
            buffer_write(_stringBuffer, buffer_text, "0x");
            buffer_write(_stringBuffer, buffer_text, string_trim_start(string(ptr(ord(_glyphChar))), _zeroSubstring));
            buffer_write(_stringBuffer, buffer_text, ",");
            ++_i;
        }
        
        buffer_poke(_stringBuffer, buffer_tell(_stringBuffer)-1, buffer_u8, 0x00);
        buffer_seek(_stringBuffer, buffer_seek_relative, -1);
        
        __MsdfTrace($"Building batch file");
        buffer_seek(_batchBuffer, buffer_seek_start, 0);
        buffer_write(_batchBuffer, buffer_text, $"pushd \"{filename_dir(_exePath)}\"\r\n");
        buffer_write(_batchBuffer, buffer_text, $"{_msdfGenExe} -font \"{_ttfPath}\" -size {_writePointSize} -pxrange {_writePxRange} -format png -imageout \"{_imageOutPath}\" -json \"{_jsonOutPath}\" -type mtsdf -yorigin top -chars ");
        buffer_copy(_stringBuffer, 0, buffer_tell(_stringBuffer), _batchBuffer, buffer_tell(_batchBuffer));
        buffer_seek(_batchBuffer, buffer_seek_relative, buffer_tell(_stringBuffer));
        
        if (_batchPreexisting)
        {
            buffer_write(_batchBuffer, buffer_text, $"\r\npause");
        }
        
        buffer_save_ext(_batchBuffer, _batchFilePath, 0, buffer_tell(_batchBuffer));
        
        if (not file_exists(_batchFilePath))
        {
            __MsdfError("\"{_batchFilePath}\" failed to save");
        }
        
        __MsdfTrace($"Executing batch file");
        execute_shell_simple(_batchFilePath);
        
        __MsdfTrace($"Waiting for batch file to finish ...");
        var _time = current_time;
        while(current_time - _time < 1500){}
        
        __MsdfTrace($"Converting MSDF data format to GameMaker data format");
        var _newYYString = _yyString;
        
        if (not file_exists(_jsonOutPath))
        {
            __MsdfError($"Expected .json file not found at \"{_jsonOutPath}\"");
        }
        
        var _msdfJSONBuffer = buffer_load(_jsonOutPath);
        if (_msdfJSONBuffer < 0)
        {
            __MsdfError($"Failed to load \"{_jsonOutPath}\"");
        }
        
        __MsdfTrace($".json size is {buffer_get_size(_msdfJSONBuffer)} bytes");
        
        var _msdfJSONString = buffer_read(_msdfJSONBuffer, buffer_text);
        buffer_delete(_msdfJSONBuffer);
        
        try
        {
            var _msdfJSON = json_parse(_msdfJSONString);
        }
        catch(_error)
        {
            __MsdfError($"Failed to parse JSON found in \"{_jsonOutPath}\"");
        }
        
        var _msdfPointSize      = _msdfJSON.atlas.size;
        var _msdfRange          = _msdfJSON.atlas.distanceRange;
        var _msdfHeight         = round(_fontPointSize*_msdfJSON.metrics.lineHeight);
        var _msdfAscenderOffset = -ceil(_fontPointSize*(_msdfJSON.metrics.lineHeight + _msdfJSON.metrics.ascender));
        __MsdfTrace($"MSDF point size is {_msdfPointSize}");
        __MsdfTrace($"MSDF range is {_msdfRange}");
        __MsdfTrace($"MSDF line height is {_msdfHeight}");
        __MsdfTrace($"MSDF equivalent ascender offset is {_msdfAscenderOffset}");
        
        __MsdfTrace("Generating new glyph data");
        var _msdGlyphArray = _msdfJSON.glyphs;
        
        buffer_seek(_stringBuffer, buffer_seek_start, 0);
        var _i = 0;
        repeat(array_length(_msdGlyphArray))
        {
            var _glyphData    = _msdGlyphArray[_i];
            var _glyphUnicode = _glyphData.unicode;
            var _glyphAtlas   = _glyphData[$ "atlasBounds"];
            var _glyphPlane   = _glyphData[$ "planeBounds"];
            
            var _glyphAdvance = round(_msdfPointSize*_glyphData.advance);
            
            buffer_write(_stringBuffer, buffer_text, "    \"");
            buffer_write(_stringBuffer, buffer_text, string(_glyphUnicode));
            buffer_write(_stringBuffer, buffer_text, "\":{\"character\":");
            buffer_write(_stringBuffer, buffer_text, string(_glyphUnicode));
            
            if ((_glyphAtlas == undefined) || (_glyphPlane == undefined)) //whitespace or non-printable
            {
                buffer_write(_stringBuffer, buffer_text, ",\"h\":");
                buffer_write(_stringBuffer, buffer_text, string(_msdfHeight));
                buffer_write(_stringBuffer, buffer_text, ",\"offset\":0,\"shift\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphAdvance));
                buffer_write(_stringBuffer, buffer_text, ",\"w\":0,\"x\":0,\"y\":0,},\n");
            }
            else
            {
                var _glyphXOffset = floor(-_msdfPointSize*_glyphPlane.left);
                var _glyphWidth   = _glyphAtlas.right - _glyphAtlas.left - MSDF_ATLAS_FIX - 1 - 2*MSDF_ATLAS_TRIM;
                var _glyphHeight  = _glyphAtlas.bottom - _glyphAtlas.top - MSDF_ATLAS_FIX - 1 - 2*MSDF_ATLAS_TRIM;
                
                buffer_write(_stringBuffer, buffer_text, ",\"h\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphHeight));
                buffer_write(_stringBuffer, buffer_text, ",\"offset\":");
                buffer_write(_stringBuffer, buffer_text, string(-_glyphXOffset));
                buffer_write(_stringBuffer, buffer_text, ",\"shift\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphAdvance));
                buffer_write(_stringBuffer, buffer_text, ",\"w\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphWidth));
                buffer_write(_stringBuffer, buffer_text, ",\"x\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphAtlas.left - 0.5 + MSDF_ATLAS_FIX + MSDF_ATLAS_TRIM));
                buffer_write(_stringBuffer, buffer_text, ",\"y\":");
                buffer_write(_stringBuffer, buffer_text, string(_glyphAtlas.top - 0.5 + MSDF_ATLAS_FIX + MSDF_ATLAS_TRIM));
                buffer_write(_stringBuffer, buffer_text, ",},\n");
            }
            
            ++_i;
        }
        
        buffer_write(_stringBuffer, buffer_u8, 0x00);
        var _glyphString = buffer_peek(_stringBuffer, 0, buffer_string);
        
        var _searchString = "\n  \"glyphs\":{\n";
        var _startPos = string_pos(_searchString, _newYYString) + string_length(_searchString);
        var _endPos = string_pos_ext("\n  },\n", _newYYString, _startPos);
        _newYYString = string_delete(_newYYString, _startPos, 1 + _endPos - _startPos);
        _newYYString = string_insert(_glyphString, _newYYString, _startPos);
        
        __MsdfTrace("Generating new kerning data");
        var _msdfKerningArray = _msdfJSON.kerning;
        
        var _searchString = "\n  \"kerningPairs\":[";
        var _startPos = string_pos(_searchString, _newYYString);
        if (_startPos <= 0)
        {
            __MsdfTrace($"Warning! Font \"{font_get_name(_font)}\" ({_font}) has no kerning data");
            ++_warnings;
        }
        else
        {
            _startPos += string_length(_searchString);
            
            var _endPos = string_pos_ext("\n  ],\n", _newYYString, _startPos);
            var _stopPos = string_pos_ext("  \"last\":", _newYYString, _startPos);
            
            var _write = false;
            if ((_endPos <= 0) || (_stopPos < _endPos))
            {
                __MsdfTrace($"Found start to kerning pair array but not end, searching for empty array");
                
                var _substring = string_copy(_newYYString, _startPos, 3);
                if (string_copy(_newYYString, _startPos, 3) == "],\n")
                {
                    __MsdfTrace($"Found empty array, splitting");
                }
                else
                {
                    __MsdfError($"Could not find kerning array in \"{_yyPath}\"");
                }
            }
            else
            {
                _newYYString = string_delete(_newYYString, _startPos, 3 + _endPos - _startPos);
            }
            
            buffer_seek(_stringBuffer, buffer_seek_start, 0);
            var _i = 0;
            repeat(array_length(_msdfKerningArray))
            {
                var _kerningData = _msdfKerningArray[_i];
                
                var _advance = round(_fontPointSize*_kerningData.advance);
                if (_advance != 0)
                {
                    buffer_write(_stringBuffer, buffer_text, "\n    {\"amount\":");
                    buffer_write(_stringBuffer, buffer_text, string(_advance));
                    buffer_write(_stringBuffer, buffer_text, ",\"first\":");
                    buffer_write(_stringBuffer, buffer_text, string(_kerningData.unicode1));
                    buffer_write(_stringBuffer, buffer_text, ",\"second\":");
                    buffer_write(_stringBuffer, buffer_text, string(_kerningData.unicode2));
                    buffer_write(_stringBuffer, buffer_text, ",},");
                }
                
                ++_i;
            }
            
            if (buffer_tell(_stringBuffer) > 0)
            {
                buffer_write(_stringBuffer, buffer_text, "\n  ");
                buffer_write(_stringBuffer, buffer_u8, 0x00);
                var _kerningString = buffer_peek(_stringBuffer, 0, buffer_string);
                _newYYString = string_insert(_kerningString, _newYYString, _startPos);
            }
        }
        
        __MsdfTrace("Generating new ascender offset");
        var _searchString = "\n  \"ascenderOffset\":";
        var _startPos = string_pos(_searchString, _newYYString);
        if (_startPos <= 0)
        {
            __MsdfError($"Could not find ascender offset value in \"{_yyPath}\"");
        }
        
        _startPos += string_length(_searchString);
        var _endPos = string_pos_ext(",\n  ", _newYYString, _startPos);
        _newYYString = string_delete(_newYYString, _startPos, _endPos - _startPos);
        _newYYString = string_insert(_msdfAscenderOffset, _newYYString, _startPos);
        
        buffer_seek(_stringBuffer, buffer_seek_start, 0);
        buffer_write(_stringBuffer, buffer_text, _newYYString);
        buffer_save_ext(_stringBuffer, $"{_fontDirectory}{_fontName}.yy", 0, buffer_tell(_stringBuffer));
        
        __MsdfTrace($"Copying new atlas texture to font directory");
        file_copy(_imageOutPath, $"{_fontDirectory}{_fontName}.png");
        
        __MsdfTrace($"Cleaning up");
        file_delete(_batchFilePath);
        file_delete(_imageOutPath);
        file_delete(_jsonOutPath);
        
        __MsdfTrace($"Finished converting font \"{font_get_name(_font)}\"");
    
        ++_i;
    }
    
    //Clean up temporary buffers
    buffer_delete(_stringBuffer);
    buffer_delete(_batchBuffer);
    
    //Report state
    if (_warnings > 0)
    {
        __MsdfTrace($"`MsdfUpdateFonts()` finished but with {_warnings} warning(s), please review your debug log");
    }
    else
    {
        __MsdfTrace("`MsdfUpdateFonts()` finished successfully with no warnings");
    }
}