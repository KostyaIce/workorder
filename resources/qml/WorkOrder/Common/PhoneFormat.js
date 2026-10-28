.pragma library

function digitsOnly(text)
{
    return text.replace(/[^0-9]/g, "")
}

// Russian mask +7 (XXX) XXX-XX-XX. A longer number keeps a leading plus and the digits.
function format(text)
{
    var digits = digitsOnly(text)
    if(digits.length === 0)
        return ""
    var body = digits
    if(body.charAt(0) === "8")
        body = "7" + body.substring(1)
    else if(body.charAt(0) !== "7")
        body = "7" + body
    if(body.length > 11)
        return "+" + digits

    var national = body.substring(1)
    var out = "+7"
    if(national.length === 0)
        return out
    out += " (" + national.substring(0, Math.min(3, national.length))
    if(national.length < 3)
        return out
    out += ")"
    if(national.length === 3)
        return out
    out += " " + national.substring(3, Math.min(6, national.length))
    if(national.length <= 6)
        return out
    out += "-" + national.substring(6, Math.min(8, national.length))
    if(national.length <= 8)
        return out
    return out + "-" + national.substring(8, 10)
}

// Keeps the caret on the same digit. Deleting only a mask character also drops the digit before it.
function edit(previous, current, cursor)
{
    var source = current
    var sourceCursor = cursor
    if(previous.length > current.length && digitsOnly(previous) === digitsOnly(current))
    {
        var digits = digitsOnly(current)
        var digitsBefore = digitsOnly(current.substring(0, cursor)).length
        if(digitsBefore > 0)
            digits = digits.substring(0, digitsBefore - 1) + digits.substring(digitsBefore)
        else if(digits.length > 0)
            digits = digits.substring(1)
        source = digits
        sourceCursor = Math.max(0, digitsBefore - 1)
    }

    var formatted = format(source)
    var sourceDigits = digitsOnly(source)
    var cursorDigits = source === current
            ? digitsOnly(current.substring(0, sourceCursor)).length
            : sourceCursor
    var prepended = sourceDigits.length > 0
            && sourceDigits.charAt(0) !== "7"
            && sourceDigits.charAt(0) !== "8"
            && ("7" + sourceDigits).length <= 11
    if(prepended)
        cursorDigits += 1

    var nextCursor = formatted.length
    if(sourceCursor < source.length)
    {
        var seen = 0
        for(var i = 0; i < formatted.length; ++i)
        {
            var ch = formatted.charAt(i)
            if(ch >= "0" && ch <= "9")
            {
                seen += 1
                if(seen >= cursorDigits)
                {
                    nextCursor = i + 1
                    break
                }
            }
        }
    }
    return { text: formatted, cursor: nextCursor }
}
