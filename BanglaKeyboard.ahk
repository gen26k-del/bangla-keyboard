; Bangla AI Keyboard - system-wide Banglish->Bangla for Windows (AutoHotkey v2)
; F9 or Ctrl+Alt+B toggles Bangla/English mode (Avro-style).
; Type Banglish in any app; on Space/punctuation the word becomes Bangla.
; Ctrl+Alt+L teaches a word. Ctrl+Alt+F fixes the last converted word.
; Learned words are saved per profile in BanglaKeyboard.ini (next to this file).
; Works fully offline.

#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------- helpers ----------
U(hex) {
    s := ""
    n := StrLen(hex) // 4
    Loop n
        s .= Chr(Integer("0x" . SubStr(hex, (A_Index - 1) * 4 + 1, 4)))
    return s
}

; ---------- engine data ----------
HASANT := Chr(0x09CD)
CHANDRA := Chr(0x0981)
ANUSVARA := Chr(0x0982)
VISARGA := Chr(0x0983)

VOWELS := Map(
    "a", [Chr(0x0986), Chr(0x09BE)],
    "aa", [Chr(0x0986), Chr(0x09BE)],
    "i", [Chr(0x0987), Chr(0x09BF)],
    "ee", [Chr(0x0988), Chr(0x09C0)],
    "I", [Chr(0x0988), Chr(0x09C0)],
    "u", [Chr(0x0989), Chr(0x09C1)],
    "oo", [Chr(0x098A), Chr(0x09C2)],
    "U", [Chr(0x098A), Chr(0x09C2)],
    "e", [Chr(0x098F), Chr(0x09C7)],
    "oi", [Chr(0x0990), Chr(0x09C8)],
    "o", [Chr(0x0985), Chr(0x09CB)],
    "O", [Chr(0x0993), Chr(0x09CB)],
    "ou", [Chr(0x0994), Chr(0x09CC)],
    "rri", [Chr(0x098B), Chr(0x09C3)]
)

CONSONANTS := Map(
    "k", Chr(0x0995), "kh", Chr(0x0996), "g", Chr(0x0997), "gh", Chr(0x0998), "Ng", Chr(0x0999),
    "c", Chr(0x099A), "ch", Chr(0x099B), "j", Chr(0x099C), "jh", Chr(0x099D),
    "T", Chr(0x099F), "Th", Chr(0x09A0), "D", Chr(0x09A1), "Dh", Chr(0x09A2), "N", Chr(0x09A3),
    "t", Chr(0x09A4), "th", Chr(0x09A5), "d", Chr(0x09A6), "dh", Chr(0x09A7), "n", Chr(0x09A8),
    "p", Chr(0x09AA), "ph", Chr(0x09AB), "f", Chr(0x09AB), "b", Chr(0x09AC), "bh", Chr(0x09AD),
    "v", Chr(0x09AD), "m", Chr(0x09AE),
    "y", Chr(0x09AF), "r", Chr(0x09B0), "l", Chr(0x09B2), "sh", Chr(0x09B6), "Sh", Chr(0x09B7),
    "s", Chr(0x09B8), "h", Chr(0x09B9),
    "R", Chr(0x09DC), "Rh", Chr(0x09DD), "Y", Chr(0x09DF), "z", Chr(0x099C), "q", Chr(0x0995),
    "w", Chr(0x0993) . Chr(0x09DF), "x", Chr(0x0995) . Chr(0x09CD) . Chr(0x09B8)
)

CONS_SPECIALS := Map(
    "kkh", Chr(0x0995) . Chr(0x09CD) . Chr(0x09B7),
    "gy", Chr(0x099C) . Chr(0x09CD) . Chr(0x099E)
)

IsVowelTok(raw) {
    global VOWELS
    return VOWELS.Has(raw)
}
IsConsTok(raw) {
    global CONSONANTS, CONS_SPECIALS
    return CONSONANTS.Has(raw) || CONS_SPECIALS.Has(raw)
}
ConsVal(raw) {
    global CONSONANTS, CONS_SPECIALS
    if (CONSONANTS.Has(raw))
        return CONSONANTS[raw]
    return CONS_SPECIALS[raw]
}

Tokenize(word) {
    global ANUSVARA, VISARGA, VOWELS
    toks := []
    n := StrLen(word)
    i := 1
    while (i <= n) {
        matched := ""
        for len in [3, 2, 1] {
            if (i + len - 1 > n)
                continue
            sub := SubStr(word, i, len)
            if (IsConsTok(sub) || IsVowelTok(sub) || sub == "ng" || sub == ":") {
                matched := sub
                break
            }
        }
        if (matched == "") {
            ch := SubStr(word, i, 1)
            low := StrLower(ch)
            if (low !== ch && (IsConsTok(low) || IsVowelTok(low))) {
                matched := low
            } else if (Ord(ch) >= 48 && Ord(ch) <= 57) {
                toks.Push(Map("raw", ch, "type", "D", "val", Chr(0x09E6 + Ord(ch) - 48)))
                i += 1
                continue
            } else {
                toks.Push(Map("raw", ch, "type", "X", "val", ch))
                i += 1
                continue
            }
        }
        if (matched == "ng")
            toks.Push(Map("raw", matched, "type", "S", "val", ANUSVARA))
        else if (matched == ":")
            toks.Push(Map("raw", matched, "type", "S", "val", VISARGA))
        else if (IsVowelTok(matched))
            toks.Push(Map("raw", matched, "type", "V", "val", VOWELS[matched]))
        else
            toks.Push(Map("raw", matched, "type", "C", "val", ConsVal(matched)))
        i += StrLen(matched)
    }
    return toks
}

ConvertWord(word) {
    global HASANT, CHANDRA
    if (word == "")
        return ""
    toks := Tokenize(word)
    out := ""
    prev := "start"
    lastKarAa := false
    idx := 1
    while (idx <= toks.Length) {
        t := toks[idx]
        hasNext := idx < toks.Length
        next := hasNext ? toks[idx + 1] : ""
        if (t["type"] == "C") {
            if (t["raw"] == "y" && prev == "vowel") {
                out .= Chr(0x09DF)
                prev := "cons"
                lastKarAa := false
                idx += 1
                continue
            }
            if (t["raw"] == "r" && prev !== "start" && hasNext && next["type"] == "C") {
                out .= Chr(0x09B0) . HASANT
                prev := "reph"
                lastKarAa := false
                idx += 1
                continue
            }
            if (t["raw"] == "n" && lastKarAa && hasNext && next["type"] == "C" && next["raw"] !== "n") {
                out .= CHANDRA
                prev := "vowel"
                lastKarAa := false
                idx += 1
                continue
            }
            if (prev == "cons")
                out .= HASANT
            out .= t["val"]
            prev := "cons"
            lastKarAa := false
        } else if (t["type"] == "V") {
            if (prev == "cons") {
                if (t["raw"] == "o") {
                    if (!hasNext)
                        out .= t["val"][2]
                    prev := "vowel"
                    lastKarAa := false
                } else {
                    out .= t["val"][2]
                    lastKarAa := (t["val"][2] == Chr(0x09BE))
                    prev := "vowel"
                }
            } else {
                out .= t["val"][1]
                prev := "vowel"
                lastKarAa := false
            }
        } else if (t["type"] == "S") {
            out .= t["val"]
            prev := "vowel"
            lastKarAa := false
        } else if (t["type"] == "D") {
            out .= t["val"]
            prev := "other"
            lastKarAa := false
        } else {
            out .= t["val"]
            prev := "other"
            lastKarAa := false
        }
        idx += 1
    }
    return out
}

; Direct conversion: learned > dictionary > phonetic
Direct(word) {
    global Learned, Dict, DictKeys, Bigram, PrevBangla
    if (word == "")
        return ""
    key := StrLower(word)
    if (Learned.Has(key))
        return Learned[key]
    if (Dict.Has(key)) {
        if (Dict[key].Length > 1 && PrevBangla != "") {
            bg := PrevBangla . "|" . key
            if (Bigram.Has(bg))
                return Bigram[bg]
        }
        return Dict[key][1]
    }
    ; closest dictionary word: tight threshold, must be a unique best match
    best := ""
    bestD := 99
    tie := false
    maxD := (StrLen(key) >= 6) ? 2 : 1
    for dk in DictKeys {
        if (Abs(StrLen(dk) - StrLen(key)) > maxD)
            continue
        d := EditDistance(key, dk)
        if (d < bestD) {
            bestD := d
            best := dk
            tie := false
        } else if (d == bestD) {
            tie := true
        }
    }
    if (best != "" && bestD <= maxD && !tie)
        return Dict[best][1]
    return ConvertWord(word)
}

PhoneticOrDict(word) {
    global Dict
    key := StrLower(word)
    if (Dict.Has(key))
        return Dict[key][1]
    return ConvertWord(word)
}

EditDistance(a, b) {
    m := StrLen(a)
    n := StrLen(b)
    if (Abs(m - n) > 2)
        return 99
    prev := []
    Loop n + 1
        prev.Push(A_Index - 1)
    i := 1
    while (i <= m) {
        cur := [i]
        j := 1
        while (j <= n) {
            cost := (SubStr(a, i, 1) == SubStr(b, j, 1)) ? 0 : 1
            cur.Push(Min(prev[j + 1] + 1, cur[j] + 1, prev[j] + cost))
            j += 1
        }
        prev := cur
        i += 1
    }
    return prev[n + 1]
}

PushSug(out, seen, b) {
    if (b == "" || seen.Has(b))
        return
    seen[b] := true
    out.Push(b)
}

SortByLen(arr) {
    n := arr.Length
    i := 2
    while (i <= n) {
        v := arr[i]
        j := i - 1
        while (j >= 1 && StrLen(arr[j]) > StrLen(v)) {
            arr[j + 1] := arr[j]
            j -= 1
        }
        arr[j + 1] := v
        i += 1
    }
}

SortFuzzy(arr) {
    n := arr.Length
    i := 2
    while (i <= n) {
        v := arr[i]
        j := i - 1
        while (j >= 1 && (arr[j][2] > v[2] || (arr[j][2] == v[2] && StrLen(arr[j][1]) > StrLen(v[1])))) {
            arr[j + 1] := arr[j]
            j -= 1
        }
        arr[j + 1] := v
        i += 1
    }
}

Suggest(word, limit, strict := false) {
    global Learned, Dict, DictKeys, PrevBangla, Followers
    out := []
    if (word == "")
        return out
    key := StrLower(word)
    seen := Map()
    if (Learned.Has(key))
        PushSug(out, seen, Learned[key])
    if (Dict.Has(key)) {
        for b in Dict[key]
            PushSug(out, seen, b)
    }
    PushSug(out, seen, strict ? Direct(word) : ConvertWord(word))
    if (!strict && StrLen(key) >= 2) {
        pre := []
        for dk in DictKeys {
            if (StrLen(dk) > StrLen(key) && SubStr(dk, 1, StrLen(key)) == key)
                pre.Push(dk)
        }
        SortByLen(pre)
        cnt := 0
        for dk in pre {
            cnt += 1
            if (cnt > 14)
                break
            for b in Dict[dk]
                PushSug(out, seen, b)
        }
    }
    if (!strict && StrLen(key) >= 4 && out.Length < limit) {
        fz := []
        for fk in DictKeys {
            if (fk == key)
                continue
            d := EditDistance(key, fk)
            if (d <= 2)
                fz.Push([fk, d])
        }
        SortFuzzy(fz)
        cnt := 0
        for e in fz {
            cnt += 1
            if (cnt > 6)
                break
            for b in Dict[e[1]]
                PushSug(out, seen, b)
        }
    }
    if (PrevBangla != "" && Followers.Has(PrevBangla)) {
        fol := Followers[PrevBangla]
        front := []
        rest := []
        for v in out {
            isFol := false
            for f in fol {
                if (f == v) {
                    isFol := true
                    break
                }
            }
            if (isFol)
                front.Push(v)
            else
                rest.Push(v)
        }
        out := []
        for v in front
            out.Push(v)
        for v in rest
            out.Push(v)
    }
    res := []
    for i, v in out {
        if (i > limit)
            break
        res.Push(v)
    }
    return res
}

; ---------- dictionary (generated from dict.js) ----------
Dict := Map()
Dict["aain"] := [U("0986098709A8")]
Dict["aam"] := [U("098609AE")]
Dict["aat"] := [U("0986099F")]
Dict["aata"] := [U("0986099F09BE")]
Dict["abar"] := [U("098609AC09BE09B0")]
Dict["abhailable"] := [U("098509CD09AF09BE09AD09C7098709B209C709AC09B2")]
Dict["aboshoi"] := [U("098509AC09B609CD09AF0987")]
Dict["aboshshoi"] := [U("098509AC09B609CD09AF0987")]
Dict["abosshoi"] := [U("098509AC09B609CD09AF0987")]
Dict["abosshoy"] := [U("098509AC09B609CD09AF0987")]
Dict["abossoi"] := [U("098509AC09B609CD09AF0987")]
Dict["ac"] := [U("098F09B809BF")]
Dict["acc"] := [U("098509CD09AF09BE099509BE098909A809CD099F")]
Dict["account"] := [U("098509CD09AF09BE099509BE098909A809CD099F")]
Dict["ace"] := [U("0986099B09C7")]
Dict["acen"] := [U("0986099B09C709A8")]
Dict["ache"] := [U("0986099B09C7")]
Dict["achen"] := [U("0986099B09C709A8")]
Dict["achi"] := [U("0986099B09BF")]
Dict["achis"] := [U("0986099B09BF09B8")]
Dict["acho"] := [U("0986099B09CB")]
Dict["achomka"] := [U("0986099A09AE099509BE")]
Dict["achw"] := [U("0986099B09CB")]
Dict["achy"] := [U("0986099B09BF")]
Dict["aci"] := [U("0986099B09BF")]
Dict["aco"] := [U("0986099B09CB")]
Dict["acount"] := [U("098509CD09AF09BE099509BE098909A809CD099F")]
Dict["ad"] := [U("098509CD09AF09BE09A1")]
Dict["ada"] := [U("098609A609BE")]
Dict["adapter"] := [U("098509CD09AF09BE09A109BE09AA09CD099F09BE09B0")]
Dict["adbhance"] := [U("098509CD09AF09BE09A109AD09BE09A809CD09B8")]
Dict["addreshs"] := [U("09A009BF099509BE09A809BE")]
Dict["address"] := [U("09A009BF099509BE09A809BE")]
Dict["admin"] := [U("098509CD09AF09BE09A109AE09BF09A8")]
Dict["adres"] := [U("09A009BF099509BE09A809BE")]
Dict["ads"] := [U("098509CD09AF09BE09A109B8")]
Dict["adsh"] := [U("098509CD09AF09BE09A109B8")]
Dict["advance"] := [U("098509CD09AF09BE09A109AD09BE09A809CD09B8")]
Dict["age"] := [U("0986099709C7")]
Dict["agei"] := [U("0986099709C70987")]
Dict["agent"] := [U("098F099C09C709A809CD099F")]
Dict["agun"] := [U("0986099709C109A8")]
Dict["airport"] := [U("098F09AF09BC09BE09B009AA09CB09B009CD099F")]
Dict["ajke"] := [U("0986099C099509C7")]
Dict["akas"] := [U("0986099509BE09B6")]
Dict["akash"] := [U("0986099509BE09B6")]
Dict["akhn"] := [U("098F099609A8")]
Dict["akhon"] := [U("098F099609A8")]
Dict["akn"] := [U("098F099609A8")]
Dict["akon"] := [U("098F099609A8")]
Dict["alada"] := [U("098609B209BE09A609BE")]
Dict["alah"] := [U("098609B209CD09B209BE09B9")]
Dict["alhamdulilah"] := [U("098609B209B909BE09AE09A609C109B209BF09B209CD09B209BE09B9")]
Dict["alhamdulillah"] := [U("098609B209B909BE09AE09A609C109B209BF09B209CD09B209BE09B9")]
Dict["allah"] := [U("098609B209CD09B209BE09B9")]
Dict["amader"] := [U("098609AE09BE09A609C709B0")]
Dict["amar"] := [U("098609AE09BE09B0")]
Dict["ami"] := [U("098609AE09BF")]
Dict["amin"] := [U("098609AE09BF09A8")]
Dict["amra"] := [U("098609AE09B009BE")]
Dict["amy"] := [U("098609AE09BF")]
Dict["angur"] := [U("0986099909C109B0")]
Dict["anondo"] := [U("098609A809A809CD09A6")]
Dict["anondw"] := [U("098609A809A809CD09A6")]
Dict["ap"] := [U("098509CD09AF09BE09AA")]
Dict["apel"] := [U("098609AA09C709B2")]
Dict["apnar"] := [U("098609AA09A809BE09B0")]
Dict["apni"] := [U("098609AA09A809BF")]
Dict["apny"] := [U("098609AA09A809BF")]
Dict["app"] := [U("098509CD09AF09BE09AA")]
Dict["apu"] := [U("098609AA09C1")]
Dict["ar"] := [U("098609B0"), U("098F09B0")]
Dict["aro"] := [U("098609B009CB")]
Dict["arw"] := [U("098609B009CB")]
Dict["asa"] := [U("098609B609BE"), U("0986099B09C7")]
Dict["asalamu"] := [U("098609B809B809BE09B209BE09AE09C1")]
Dict["asalamualaikum"] := [U("098609B809B809BE09B209BE09AE09C10020098609B209BE0987099509C109AE")]
Dict["asbe"] := [U("098609B809AC09C7")]
Dict["asben"] := [U("098609B809AC09C709A8")]
Dict["asbo"] := [U("098609B809AC09CB")]
Dict["asbona"] := [U("098609B809AC09CB09A809BE")]
Dict["asbw"] := [U("098609B809AC09CB")]
Dict["asce"] := [U("098609B8099B09C7")]
Dict["asche"] := [U("098609B8099B09C7")]
Dict["aschi"] := [U("098609B8099B09BF")]
Dict["ascho"] := [U("098609B8099B09CB")]
Dict["aschorjo"] := [U("098609B609CD099A09B009CD09AF")]
Dict["asci"] := [U("098609B8099B09BF")]
Dict["asco"] := [U("098609B8099B09CB")]
Dict["ascorjo"] := [U("098609B609CD099A09B009CD09AF")]
Dict["ase"] := [U("098609B809C7")]
Dict["asha"] := [U("098609B609BE")]
Dict["ashbe"] := [U("098609B809AC09C7")]
Dict["ashben"] := [U("098609B809AC09C709A8")]
Dict["ashbo"] := [U("098609B809AC09CB")]
Dict["ashbona"] := [U("098609B809AC09CB09A809BE")]
Dict["ashbw"] := [U("098609B809AC09CB")]
Dict["ashce"] := [U("098609B8099B09C7")]
Dict["ashche"] := [U("098609B8099B09C7")]
Dict["ashchi"] := [U("098609B8099B09BF")]
Dict["ashcho"] := [U("098609B8099B09CB")]
Dict["ashchorjo"] := [U("098609B609CD099A09B009CD09AF")]
Dict["ashchorjw"] := [U("098609B609CD099A09B009CD09AF")]
Dict["ashchorzo"] := [U("098609B609CD099A09B009CD09AF")]
Dict["ashchw"] := [U("098609B8099B09CB")]
Dict["ashchy"] := [U("098609B8099B09BF")]
Dict["ashci"] := [U("098609B8099B09BF")]
Dict["ashco"] := [U("098609B8099B09CB")]
Dict["ashcorjo"] := [U("098609B609CD099A09B009CD09AF")]
Dict["ashe"] := [U("098609B809C7")]
Dict["ashi"] := [U("098609B809BF"), U("098609B609BF")]
Dict["ashia"] := [U("098F09B809C7")]
Dict["ashmani"] := [U("098609B809AE09BE09A809BF")]
Dict["ashmany"] := [U("098609B809AE09BE09A809BF")]
Dict["asho"] := [U("098609B809CB")]
Dict["ashsalamu"] := [U("098609B809B809BE09B209BE09AE09C1")]
Dict["ashsalamualaikum"] := [U("098609B809B809BE09B209BE09AE09C10020098609B209BE0987099509C109AE")]
Dict["ashtagfirullah"] := [U("098609B809CD09A409BE099709AB09BF09B009C109B209CD09B209BE09B9")]
Dict["ashte"] := [U("098609B809A409C7")]
Dict["ashun"] := [U("098609B809C109A8")]
Dict["ashw"] := [U("098609B809CB")]
Dict["ashy"] := [U("098609B809BF"), U("098609B609BF")]
Dict["asi"] := [U("098609B809BF"), U("098609B609BF"), U("0986099B09BF")]
Dict["asmani"] := [U("098609B809AE09BE09A809BF")]
Dict["aso"] := [U("098609B809CB"), U("0986099B09CB")]
Dict["assalamu"] := [U("098609B809B809BE09B209BE09AE09C1")]
Dict["assalamualaikum"] := [U("098609B809B809BE09B209BE09AE09C10020098609B209BE0987099509C109AE")]
Dict["astagfirulah"] := [U("098609B809CD09A409BE099709AB09BF09B009C109B209CD09B209BE09B9")]
Dict["astagfirullah"] := [U("098609B809CD09A409BE099709AB09BF09B009C109B209CD09B209BE09B9")]
Dict["astagphirullah"] := [U("098609B809CD09A409BE099709AB09BF09B009C109B209CD09B209BE09B9")]
Dict["aste"] := [U("098609B809CD09A409C7")]
Dict["asun"] := [U("098609B809C109A8")]
Dict["atero"] := [U("098609A009BE09B009CB")]
Dict["athero"] := [U("098609A009BE09B009CB")]
Dict["atherw"] := [U("098609A009BE09B009CB")]
Dict["auto"] := [U("0985099F09CB")]
Dict["autw"] := [U("0985099F09CB")]
Dict["available"] := [U("098509CD09AF09BE09AD09C7098709B209C709AC09B2")]
Dict["ay"] := [U("098609AF09BC")]
Dict["azke"] := [U("0986099C099509C7")]
Dict["baba"] := [U("09AC09BE09AC09BE")]
Dict["badam"] := [U("09AC09BE09A609BE09AE")]
Dict["badami"] := [U("09AC09BE09A609BE09AE09BF")]
Dict["badamy"] := [U("09AC09BE09A609BE09AE09BF")]
Dict["bag"] := [U("09AC09CD09AF09BE0997")]
Dict["baire"] := [U("09AC09BE098709B009C7")]
Dict["bajar"] := [U("09AC09BE099C09BE09B0")]
Dict["baje"] := [U("09AC09BE099C09C7")]
Dict["baki"] := [U("09AC09BE099509BF")]
Dict["baky"] := [U("09AC09BE099509BF")]
Dict["balo"] := [U("09AD09BE09B209CB")]
Dict["balobasha"] := [U("09AD09BE09B209CB09AC09BE09B809BE")]
Dict["banabo"] := [U("09AC09BE09A809BE09AC09CB")]
Dict["banabw"] := [U("09AC09BE09A809BE09AC09CB")]
Dict["banai"] := [U("09AC09BE09A809BE0987")]
Dict["banate"] := [U("09AC09BE09A809BE09A409C7")]
Dict["banay"] := [U("09AC09BE09A809BE0987")]
Dict["bangla"] := [U("09AC09BE098209B209BE")]
Dict["banglades"] := [U("09AC09BE098209B209BE09A609C709B6")]
Dict["bangladesh"] := [U("09AC09BE098209B209BE09A609C709B6")]
Dict["bank"] := [U("09AC09CD09AF09BE09820995")]
Dict["baranda"] := [U("09AC09BE09B009BE09A809CD09A609BE")]
Dict["barano"] := [U("09AC09BE09A109BC09BE09A809CB")]
Dict["baranw"] := [U("09AC09BE09A109BC09BE09A809CB")]
Dict["barbe"] := [U("09AC09BE09A109BC09AC09C7")]
Dict["bari"] := [U("09AC09BE09A109BC09BF")]
Dict["baro"] := [U("09AC09BE09B009CB")]
Dict["barw"] := [U("09AC09BE09B009CB")]
Dict["bary"] := [U("09AC09BE09A109BC09BF")]
Dict["batas"] := [U("09AC09BE09A409BE09B8")]
Dict["batash"] := [U("09AC09BE09A409BE09B8")]
Dict["batery"] := [U("09AC09CD09AF09BE099F09BE09B009BF")]
Dict["bathroom"] := [U("09AC09BE09A509B009C109AE")]
Dict["bathrum"] := [U("09AC09BE09A509B009C109AE")]
Dict["batroom"] := [U("09AC09BE09A509B009C109AE")]
Dict["batteri"] := [U("09AC09CD09AF09BE099F09BE09B009BF")]
Dict["battery"] := [U("09AC09CD09AF09BE099F09BE09B009BF")]
Dict["bazar"] := [U("09AC09BE099C09BE09B0")]
Dict["baze"] := [U("09AC09BE099C09C7")]
Dict["becbo"] := [U("09AC09C7099A09AC09CB")]
Dict["bechbo"] := [U("09AC09C7099A09AC09CB")]
Dict["bechbw"] := [U("09AC09C7099A09AC09CB")]
Dict["bechi"] := [U("09AC09C7099A09BF")]
Dict["bechte"] := [U("09AC09C7099A09A409C7")]
Dict["bechy"] := [U("09AC09C7099A09BF")]
Dict["beci"] := [U("09AC09C7099A09BF")]
Dict["becte"] := [U("09AC09C7099A09A409C7")]
Dict["bed"] := [U("099609BE099F")]
Dict["beguni"] := [U("09AC09C7099709C109A809BF")]
Dict["beguny"] := [U("09AC09C7099709C109A809BF")]
Dict["bei"] := [U("09AC09CD09AF09AF09BC")]
Dict["bekar"] := [U("09AC09C7099509BE09B0")]
Dict["berece"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["bereche"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["beshi"] := [U("09AC09C709B609BF")]
Dict["beshy"] := [U("09AC09C709B609BF")]
Dict["besi"] := [U("09AC09C709B609BF")]
Dict["beton"] := [U("09AC09C709A409A8")]
Dict["bey"] := [U("09AC09CD09AF09AF09BC")]
Dict["bhaat"] := [U("09AD09BE09A4")]
Dict["bhabe"] := [U("09AD09BE09AC09C7")]
Dict["bhabi"] := [U("09AD09BE09AC09BF")]
Dict["bhabo"] := [U("09AD09BE09AC09CB")]
Dict["bhabw"] := [U("09AD09BE09AC09CB")]
Dict["bhaby"] := [U("09AD09BE09AC09BF")]
Dict["bhai"] := [U("09AD09BE0987")]
Dict["bhaiya"] := [U("09AD09BE098709AF09BC09BE")]
Dict["bhalo"] := [U("09AD09BE09B209CB")]
Dict["bhalobasa"] := [U("09AD09BE09B209CB09AC09BE09B809BE")]
Dict["bhalobasha"] := [U("09AD09BE09B209CB09AC09BE09B809BE")]
Dict["bhalw"] := [U("09AD09BE09B209CB")]
Dict["bhan"] := [U("09AD09CD09AF09BE09A8")]
Dict["bhasa"] := [U("09AD09BE09B709BE")]
Dict["bhasha"] := [U("09AD09BE09B709BE")]
Dict["bhay"] := [U("09AD09BE0987")]
Dict["bheja"] := [U("09AD09C7099C09BE")]
Dict["bherify"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["bhersion"] := [U("09AD09BE09B009CD09B809A8")]
Dict["bhid"] := [U("09AD09BF09A109BF0993")]
Dict["bhideo"] := [U("09AD09BF09A109BF0993")]
Dict["bhinno"] := [U("09AD09BF09A809CD09A8")]
Dict["bhisa"] := [U("09AD09BF09B809BE")]
Dict["bhitore"] := [U("09AD09BF09A409B009C7")]
Dict["bhoi"] := [U("09AD09AF09BC")]
Dict["bhor"] := [U("09AD09CB09B0")]
Dict["bhote"] := [U("09AD09CB099F")]
Dict["bhoucher"] := [U("09AD09BE0989099A09BE09B0")]
Dict["bhoy"] := [U("09AD09AF09BC")]
Dict["bhugol"] := [U("09AD09C2099709CB09B2")]
Dict["bhul"] := [U("09AD09C109B2")]
Dict["bicycle"] := [U("09B809BE0987099509C709B2")]
Dict["bidai"] := [U("09AC09BF09A609BE09AF09BC")]
Dict["biday"] := [U("09AC09BF09A609BE09AF09BC")]
Dict["biddut"] := [U("09AC09BF09A609CD09AF09C109CE")]
Dict["bidut"] := [U("09AC09BF09A609CD09AF09C109CE")]
Dict["bigan"] := [U("09AC09BF099C09CD099E09BE09A8")]
Dict["biggan"] := [U("09AC09BF099C09CD099E09BE09A8")]
Dict["biia"] := [U("09AC09BF09AF09BC09C7")]
Dict["bijoi"] := [U("09AC09BF099C09AF09BC")]
Dict["bijoy"] := [U("09AC09BF099C09AF09BC")]
Dict["bike"] := [U("09AC09BE09870995")]
Dict["bikel"] := [U("09AC09BF099509C709B2")]
Dict["bil"] := [U("09AC09BF09B2")]
Dict["bill"] := [U("09AC09BF09B2")]
Dict["biman"] := [U("09AC09BF09AE09BE09A8")]
Dict["birokto"] := [U("09AC09BF09B0099509CD09A4")]
Dict["biroktw"] := [U("09AC09BF09B0099509CD09A4")]
Dict["birt"] := [U("099C09A809CD09AE")]
Dict["birth"] := [U("099C09A809CD09AE")]
Dict["biryani"] := [U("09AC09BF09B009BF09AF09BC09BE09A809BF")]
Dict["biryany"] := [U("09AC09BF09B009BF09AF09BC09BE09A809BF")]
Dict["bis"] := [U("09AC09BF09B6")]
Dict["bish"] := [U("09AC09BF09B6")]
Dict["bishmillah"] := [U("09AC09BF09B809AE09BF09B209CD09B209BE09B9")]
Dict["bishoi"] := [U("09AC09BF09B709AF09BC")]
Dict["bishoy"] := [U("09AC09BF09B709AF09BC")]
Dict["bismilah"] := [U("09AC09BF09B809AE09BF09B209CD09B209BE09B9")]
Dict["bismillah"] := [U("09AC09BF09B809AE09BF09B209CD09B209BE09B9")]
Dict["bisoi"] := [U("09AC09BF09B709AF09BC")]
Dict["bisoy"] := [U("09AC09BF09B709AF09BC")]
Dict["biya"] := [U("09AC09BF09AF09BC09C7")]
Dict["biye"] := [U("09AC09BF09AF09BC09C7")]
Dict["bizoy"] := [U("09AC09BF099C09AF09BC")]
Dict["bji"] := [U("09AC09C1099D09BF")]
Dict["bjlm"] := [U("09AC09C1099D09B209BE09AE")]
Dict["bkas"] := [U("09AC09BF099509BE09B6")]
Dict["bkash"] := [U("09AC09BF099509BE09B6")]
Dict["blbo"] := [U("09AC09B209AC09CB")]
Dict["blbw"] := [U("09AC09B209AC09CB")]
Dict["bli"] := [U("09AC09B209BF")]
Dict["block"] := [U("09AC09CD09B20995")]
Dict["blte"] := [U("09AC09B209A409C7")]
Dict["bly"] := [U("09AC09B209BF")]
Dict["bochor"] := [U("09AC099B09B0")]
Dict["bocor"] := [U("09AC099B09B0")]
Dict["boi"] := [U("09AC0987")]
Dict["bojhano"] := [U("09AC09CB099D09BE09A809CB")]
Dict["bojhanw"] := [U("09AC09CB099D09BE09A809CB")]
Dict["boka"] := [U("09AC09CB099509BE")]
Dict["bokeya"] := [U("09AC099509C709AF09BC09BE")]
Dict["bolbe"] := [U("09AC09B209AC09C7")]
Dict["bolben"] := [U("09AC09B209AC09C709A8")]
Dict["bolbo"] := [U("09AC09B209AC09CB")]
Dict["bolbona"] := [U("09AC09B209AC09CB09A809BE")]
Dict["bolbw"] := [U("09AC09B209AC09CB")]
Dict["bolce"] := [U("09AC09B2099B09C7")]
Dict["bolche"] := [U("09AC09B2099B09C7")]
Dict["bolchi"] := [U("09AC09B2099B09BF")]
Dict["bolcho"] := [U("09AC09B2099B09CB")]
Dict["bolchw"] := [U("09AC09B2099B09CB")]
Dict["bolchy"] := [U("09AC09B2099B09BF")]
Dict["bolci"] := [U("09AC09B2099B09BF")]
Dict["bolco"] := [U("09AC09B2099B09CB")]
Dict["bole"] := [U("09AC09B209C7")]
Dict["boleche"] := [U("09AC09B209C7099B09C7")]
Dict["bolechhe"] := [U("09AC09B209C7099B09C7")]
Dict["bolechi"] := [U("09AC09B209C7099B09BF")]
Dict["bolecho"] := [U("09AC09B209C7099B09CB")]
Dict["bolechw"] := [U("09AC09B209C7099B09CB")]
Dict["bolechy"] := [U("09AC09B209C7099B09BF")]
Dict["boleci"] := [U("09AC09B209C7099B09BF")]
Dict["boleco"] := [U("09AC09B209C7099B09CB")]
Dict["boli"] := [U("09AC09B209BF")]
Dict["bolia"] := [U("09AC09B209C7")]
Dict["bolo"] := [U("09AC09B209CB")]
Dict["bolte"] := [U("09AC09B209A409C7")]
Dict["bolun"] := [U("09AC09B209C109A8")]
Dict["bolw"] := [U("09AC09B209CB")]
Dict["boly"] := [U("09AC09B209BF")]
Dict["bon"] := [U("09AC09CB09A8"), U("09AC09A8")]
Dict["bondhu"] := [U("09AC09A809CD09A709C1")]
Dict["bondhuto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bondhutto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bondhuttw"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bondu"] := [U("09AC09A809CD09A709C1")]
Dict["bondutto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bonus"] := [U("09AC09CB09A809BE09B8")]
Dict["bonush"] := [U("09AC09CB09A809BE09B8")]
Dict["boosht"] := [U("09AC09C109B809CD099F")]
Dict["boost"] := [U("09AC09C109B809CD099F")]
Dict["boro"] := [U("09AC09A109BC")]
Dict["borof"] := [U("09AC09B009AB")]
Dict["boroph"] := [U("09AC09B009AB")]
Dict["borsa"] := [U("09AC09B009CD09B709BE")]
Dict["borsha"] := [U("09AC09B009CD09B709BE")]
Dict["borw"] := [U("09AC09A109BC")]
Dict["bose"] := [U("09AC09B809C7")]
Dict["boshe"] := [U("09AC09B809C7")]
Dict["boshi"] := [U("09AC09B809BF")]
Dict["bosho"] := [U("09AC09B809CB")]
Dict["boshonto"] := [U("09AC09B809A809CD09A4")]
Dict["boshw"] := [U("09AC09B809CB")]
Dict["boshy"] := [U("09AC09B809BF")]
Dict["bosi"] := [U("09AC09B809BF")]
Dict["boso"] := [U("09AC09B809CB")]
Dict["bosonto"] := [U("09AC09B809A809CD09A4")]
Dict["bosontw"] := [U("09AC09B809A809CD09A4")]
Dict["botle"] := [U("09AC09CB09A409B2")]
Dict["bottle"] := [U("09AC09CB09A409B2")]
Dict["bou"] := [U("09AC0989")]
Dict["box"] := [U("09AC099509CD09B8")]
Dict["boy"] := [U("09AC0987")]
Dict["boyos"] := [U("09AC09AF09BC09B8")]
Dict["boyosh"] := [U("09AC09AF09BC09B8")]
Dict["bozhano"] := [U("09AC09CB099D09BE09A809CB")]
Dict["brand"] := [U("09AC09CD09B009CD09AF09BE09A809CD09A1")]
Dict["brihoshpotibar"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["brihospotibar"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["brishti"] := [U("09AC09C309B709CD099F09BF")]
Dict["brishty"] := [U("09AC09C309B709CD099F09BF")]
Dict["bristi"] := [U("09AC09C309B709CD099F09BF")]
Dict["bro"] := [U("09AC09CD09B009CB")]
Dict["brw"] := [U("09AC09CD09B009CB")]
Dict["budbar"] := [U("09AC09C109A709AC09BE09B0")]
Dict["buddhi"] := [U("09AC09C109A609CD09A709BF")]
Dict["buddhiman"] := [U("09AC09C109A609CD09A709BF09AE09BE09A8")]
Dict["buddhy"] := [U("09AC09C109A609CD09A709BF")]
Dict["buddi"] := [U("09AC09C109A609CD09A709BF")]
Dict["buddiman"] := [U("09AC09C109A609CD09A709BF09AE09BE09A8")]
Dict["budhbar"] := [U("09AC09C109A709AC09BE09B0")]
Dict["budhi"] := [U("09AC09C109A609CD09A709BF")]
Dict["budhiman"] := [U("09AC09C109A609CD09A709BF09AE09BE09A8")]
Dict["bujhchi"] := [U("09AC09C1099D099B09BF")]
Dict["bujhchy"] := [U("09AC09C1099D099B09BF")]
Dict["bujhci"] := [U("09AC09C1099D099B09BF")]
Dict["bujhe"] := [U("09AC09C1099D09C7")]
Dict["bujheche"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bujhechhe"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bujhechi"] := [U("09AC09C1099D09C7099B09BF")]
Dict["bujhecho"] := [U("09AC09C1099D09C7099B09CB")]
Dict["bujhechw"] := [U("09AC09C1099D09C7099B09CB")]
Dict["bujhechy"] := [U("09AC09C1099D09C7099B09BF")]
Dict["bujheci"] := [U("09AC09C1099D09C7099B09BF")]
Dict["bujheco"] := [U("09AC09C1099D09C7099B09CB")]
Dict["bujhen"] := [U("09AC09C1099D09C709A8")]
Dict["bujhi"] := [U("09AC09C1099D09BF")]
Dict["bujhia"] := [U("09AC09C1099D09C7")]
Dict["bujhina"] := [U("09AC09C1099D09BF09A809BE")]
Dict["bujho"] := [U("09AC09C1099D09CB")]
Dict["bujhte"] := [U("09AC09C1099D09A409C7")]
Dict["bujhw"] := [U("09AC09C1099D09CB")]
Dict["bujhy"] := [U("09AC09C1099D09BF")]
Dict["bulb"] := [U("09AC09BE09B209CD09AC")]
Dict["bus"] := [U("09AC09BE09B8")]
Dict["bush"] := [U("09AC09BE09B8")]
Dict["bushineshs"] := [U("09AC09BF099C09A809C709B8")]
Dict["bushy"] := [U("09AC09CD09AF09B809CD09A4")]
Dict["busi"] := [U("09AC09CD09AF09B809CD09A4")]
Dict["busines"] := [U("09AC09BF099C09A809C709B8")]
Dict["business"] := [U("09AC09BF099C09A809C709B8")]
Dict["bust"] := [U("09AC09C109B809CD099F")]
Dict["busy"] := [U("09AC09CD09AF09B809CD09A4")]
Dict["buton"] := [U("09AC09BE099F09A8")]
Dict["button"] := [U("09AC09BE099F09A8")]
Dict["buzhchi"] := [U("09AC09C1099D099B09BF")]
Dict["buzhe"] := [U("09AC09C1099D09C7")]
Dict["buzhechhe"] := [U("09AC09C1099D09C7099B09C7")]
Dict["buzhechi"] := [U("09AC09C1099D09C7099B09BF")]
Dict["buzhecho"] := [U("09AC09C1099D09C7099B09CB")]
Dict["buzhen"] := [U("09AC09C1099D09C709A8")]
Dict["buzhi"] := [U("09AC09C1099D09BF")]
Dict["buzhina"] := [U("09AC09C1099D09BF09A809BE")]
Dict["buzho"] := [U("09AC09C1099D09CB")]
Dict["buzhte"] := [U("09AC09C1099D09A409C7")]
Dict["byayam"] := [U("09AC09CD09AF09BE09AF09BC09BE09AE")]
Dict["bye"] := [U("09AC09BE0987")]
Dict["bzi"] := [U("09AC09C1099D09BF")]
Dict["bzlm"] := [U("09AC09C1099D09B209BE09AE")]
Dict["bzy"] := [U("09AC09C1099D09BF")]
Dict["ca"] := [U("099A09BE")]
Dict["caand"] := [U("099A09BE098109A6")]
Dict["cable"] := [U("099509CD09AF09BE09AC09B2")]
Dict["caca"] := [U("099A09BE099A09BE")]
Dict["cad"] := [U("099B09BE09A6")]
Dict["cai"] := [U("099A09BE0987")]
Dict["caibo"] := [U("099A09BE098709AC09CB")]
Dict["caina"] := [U("099A09BE098709A809BE")]
Dict["cair"] := [U("099A09C709AF09BC09BE09B0")]
Dict["caite"] := [U("099A09BE098709A409C7")]
Dict["cakri"] := [U("099A09BE099509B009BF")]
Dict["cal"] := [U("099A09BE09B2")]
Dict["calak"] := [U("099A09BE09B209BE0995")]
Dict["calendar"] := [U("099509CD09AF09BE09B209C709A809CD09A109BE09B0")]
Dict["call"] := [U("099509B2")]
Dict["callis"] := [U("099A09B209CD09B209BF09B6")]
Dict["callish"] := [U("099A09B209CD09B209BF09B6")]
Dict["camera"] := [U("099509CD09AF09BE09AE09C709B009BE")]
Dict["can"] := [U("099A09BE09A8")]
Dict["cancel"] := [U("099509CD09AF09BE09A809B809C709B2")]
Dict["cand"] := [U("099A09BE098109A6")]
Dict["cao"] := [U("099A09BE0993")]
Dict["car"] := [U("099509BE09B0")]
Dict["card"] := [U("099509BE09B009CD09A1")]
Dict["carge"] := [U("099A09BE09B009CD099C")]
Dict["carger"] := [U("099A09BE09B009CD099C09BE09B0")]
Dict["cas"] := [U("099509CD09AF09BE09B6")]
Dict["case"] := [U("099509C709B8")]
Dict["cash"] := [U("099509CD09AF09BE09B6")]
Dict["cashe"] := [U("099509C709B8")]
Dict["catalog"] := [U("099509CD09AF09BE099F09BE09B20997")]
Dict["catro"] := [U("099B09BE09A409CD09B0")]
Dict["cay"] := [U("099A09BE09AF09BC")]
Dict["cbo"] := [U("099A09BE098709AC09CB")]
Dict["ceck"] := [U("099A09C70995")]
Dict["cele"] := [U("099B09C709B209C7")]
Dict["ceque"] := [U("099A09C70995")]
Dict["certificate"] := [U("09B809BE09B009CD099F09BF09AB09BF099509C7099F")]
Dict["certiphicate"] := [U("09B809BE09B009CD099F09BF09AB09BF099509C7099F")]
Dict["cha"] := [U("099A09BE")]
Dict["chaand"] := [U("099A09BE098109A6")]
Dict["chacha"] := [U("099A09BE099A09BE")]
Dict["chad"] := [U("099B09BE09A6"), U("099A09BE098109A6")]
Dict["chai"] := [U("099A09BE0987")]
Dict["chaibo"] := [U("099A09BE098709AC09CB")]
Dict["chaibw"] := [U("099A09BE098709AC09CB")]
Dict["chaina"] := [U("099A09BE098709A809BE")]
Dict["chair"] := [U("099A09C709AF09BC09BE09B0")]
Dict["chaite"] := [U("099A09BE098709A409C7")]
Dict["chakri"] := [U("099A09BE099509B009BF")]
Dict["chakry"] := [U("099A09BE099509B009BF")]
Dict["chal"] := [U("099A09BE09B2")]
Dict["chalak"] := [U("099A09BE09B209BE0995")]
Dict["chalish"] := [U("099A09B209CD09B209BF09B6")]
Dict["challis"] := [U("099A09B209CD09B209BF09B6")]
Dict["challish"] := [U("099A09B209CD09B209BF09B6")]
Dict["chan"] := [U("099A09BE09A8")]
Dict["chand"] := [U("099A09BE098109A6")]
Dict["chao"] := [U("099A09BE0993")]
Dict["char"] := [U("099A09BE09B0")]
Dict["charge"] := [U("099A09BE09B009CD099C")]
Dict["charger"] := [U("099A09BE09B009CD099C09BE09B0")]
Dict["chatro"] := [U("099B09BE09A409CD09B0")]
Dict["chatrw"] := [U("099B09BE09A409CD09B0")]
Dict["chaw"] := [U("099A09BE0993")]
Dict["chay"] := [U("099A09BE09AF09BC")]
Dict["chbo"] := [U("099A09BE098709AC09CB")]
Dict["chbw"] := [U("099A09BE098709AC09CB")]
Dict["check"] := [U("099A09C70995")]
Dict["chele"] := [U("099B09C709B209C7")]
Dict["cheque"] := [U("099A09C70995")]
Dict["chhad"] := [U("099B09BE09A6")]
Dict["chhatro"] := [U("099B09BE09A409CD09B0")]
Dict["chhatrw"] := [U("099B09BE09A409CD09B0")]
Dict["chhuti"] := [U("099B09C1099F09BF")]
Dict["chhuty"] := [U("099B09C1099F09BF")]
Dict["chikitsa"] := [U("099A09BF099509BF09CE09B809BE")]
Dict["chikitsha"] := [U("099A09BF099509BF09CE09B809BE")]
Dict["chini"] := [U("099A09BF09A809BF")]
Dict["chinta"] := [U("099A09BF09A809CD09A409BE")]
Dict["chiny"] := [U("099A09BF09A809BF")]
Dict["chithi"] := [U("099A09BF09A009BF")]
Dict["chithy"] := [U("099A09BF09A009BF")]
Dict["chiti"] := [U("099A09BF09A009BF")]
Dict["chobi"] := [U("099B09AC09BF")]
Dict["choby"] := [U("099B09AC09BF")]
Dict["choi"] := [U("099B09AF09BC")]
Dict["chok"] := [U("099A09CB0996")]
Dict["chokh"] := [U("099A09CB0996")]
Dict["cholben"] := [U("099A09B209AC09C709A8")]
Dict["cholbo"] := [U("099A09B209AC09CB")]
Dict["cholbw"] := [U("099A09B209AC09CB")]
Dict["chole"] := [U("099A09B209C7")]
Dict["choli"] := [U("099A09B209BF")]
Dict["cholo"] := [U("099A09B209CB")]
Dict["cholte"] := [U("099A09B209A409C7")]
Dict["cholw"] := [U("099A09B209CB")]
Dict["choly"] := [U("099A09B209BF")]
Dict["chomotkar"] := [U("099A09AE09CE099509BE09B0")]
Dict["choto"] := [U("099B09CB099F")]
Dict["chotw"] := [U("099B09CB099F")]
Dict["chouddo"] := [U("099A09CC09A609CD09A6")]
Dict["chouddw"] := [U("099A09CC09A609CD09A6")]
Dict["choudo"] := [U("099A09CC09A609CD09A6")]
Dict["choy"] := [U("099B09AF09BC")]
Dict["chul"] := [U("099A09C109B2")]
Dict["chup"] := [U("099A09C109AA")]
Dict["chupchap"] := [U("099A09C109AA099A09BE09AA")]
Dict["chuti"] := [U("099B09C1099F09BF")]
Dict["chuty"] := [U("099B09C1099F09BF")]
Dict["cikitsa"] := [U("099A09BF099509BF09CE09B809BE")]
Dict["cikitsha"] := [U("099A09BF099509BF09CE09B809BE")]
Dict["cinema"] := [U("09B809BF09A809C709AE09BE")]
Dict["cini"] := [U("099A09BF09A809BF")]
Dict["cinta"] := [U("099A09BF09A809CD09A409BE")]
Dict["cithi"] := [U("099A09BF09A009BF")]
Dict["click"] := [U("099509CD09B209BF0995")]
Dict["clinic"] := [U("099509CD09B209BF09A809BF0995")]
Dict["close"] := [U("099509CD09B209CB099C")]
Dict["closhe"] := [U("099509CD09B209CB099C")]
Dict["cng"] := [U("09B809BF098F09A8099C09BF")]
Dict["cobher"] := [U("099509AD09BE09B0")]
Dict["cobi"] := [U("099B09AC09BF")]
Dict["code"] := [U("099509CB09A1")]
Dict["cofee"] := [U("099509AB09BF")]
Dict["coffee"] := [U("099509AB09BF")]
Dict["coffi"] := [U("099509AB09BF")]
Dict["cokh"] := [U("099A09CB0996")]
Dict["colben"] := [U("099A09B209AC09C709A8")]
Dict["colbo"] := [U("099A09B209AC09CB")]
Dict["cole"] := [U("099A09B209C7")]
Dict["colege"] := [U("099509B209C7099C")]
Dict["coli"] := [U("099A09B209BF")]
Dict["college"] := [U("099509B209C7099C")]
Dict["colo"] := [U("099A09B209CB")]
Dict["color"] := [U("099509BE09B209BE09B0")]
Dict["colour"] := [U("099509BE09B209BE09B0")]
Dict["colte"] := [U("099A09B209A409C7")]
Dict["coment"] := [U("099509AE09C709A809CD099F")]
Dict["comision"] := [U("099509AE09BF09B609A8")]
Dict["comment"] := [U("099509AE09C709A809CD099F")]
Dict["commishsion"] := [U("099509AE09BF09B609A8")]
Dict["commission"] := [U("099509AE09BF09B609A8")]
Dict["comotkar"] := [U("099A09AE09CE099509BE09B0")]
Dict["compani"] := [U("099509CB09AE09CD09AA09BE09A809BF")]
Dict["company"] := [U("099509CB09AE09CD09AA09BE09A809BF")]
Dict["computer"] := [U("099509AE09CD09AA09BF0989099F09BE09B0")]
Dict["confirm"] := [U("099509A809AB09BE09B009CD09AE")]
Dict["conphirm"] := [U("099509A809AB09BE09B009CD09AE")]
Dict["cophphee"] := [U("099509AB09BF")]
Dict["copi"] := [U("099509AA09BF")]
Dict["copy"] := [U("099509AA09BF")]
Dict["coto"] := [U("099B09CB099F")]
Dict["couddo"] := [U("099A09CC09A609CD09A6")]
Dict["cover"] := [U("099509AD09BE09B0")]
Dict["coy"] := [U("099B09AF09BC")]
Dict["credit"] := [U("099509CD09B009C709A109BF099F")]
Dict["cricket"] := [U("099509CD09B009BF099509C7099F")]
Dict["cul"] := [U("099A09C109B2")]
Dict["cup"] := [U("099A09C109AA")]
Dict["cupcap"] := [U("099A09C109AA099A09BE09AA")]
Dict["curent"] := [U("099509BE09B009C709A809CD099F")]
Dict["current"] := [U("099509BE09B009C709A809CD099F")]
Dict["cushtomer"] := [U("099509BE09B809CD099F09AE09BE09B0")]
Dict["customer"] := [U("099509BE09B809CD099F09AE09BE09B0")]
Dict["cuti"] := [U("099B09C1099F09BF")]
Dict["cycle"] := [U("09B809BE0987099509C709B2")]
Dict["dada"] := [U("09A609BE09A609BE")]
Dict["dadi"] := [U("09A609BE09A609BF")]
Dict["dady"] := [U("09A609BE09A609BF")]
Dict["daka"] := [U("09A209BE099509BE")]
Dict["dal"] := [U("09A109BE09B2")]
Dict["dam"] := [U("09A609BE09AE")]
Dict["damadami"] := [U("09A609BE09AE09BE09A609BE09AE09BF")]
Dict["damadamy"] := [U("09A609BE09AE09BE09A609BE09AE09BF")]
Dict["dami"] := [U("09A609BE09AE09BF")]
Dict["damy"] := [U("09A609BE09AE09BF")]
Dict["dao"] := [U("09A609BE0993")]
Dict["darai"] := [U("09A609BE098109A109BC09BE0987")]
Dict["darano"] := [U("09A609BE098109A109BC09BE09A809CB")]
Dict["daranw"] := [U("09A609BE098109A109BC09BE09A809CB")]
Dict["darao"] := [U("09A609BE098109A109BC09BE0993")]
Dict["daraw"] := [U("09A609BE098109A109BC09BE0993")]
Dict["daray"] := [U("09A609BE098109A109BC09BE09AF09BC")]
Dict["darun"] := [U("09A609BE09B009C109A3")]
Dict["data"] := [U("09A109C7099F09BE")]
Dict["date"] := [U("09A109C7099F")]
Dict["daw"] := [U("09A609BE0993")]
Dict["dealer"] := [U("09A109BF09B209BE09B0")]
Dict["dear"] := [U("09A109BF09AF09BC09BE09B0")]
Dict["debit"] := [U("09A109C709AC09BF099F")]
Dict["dei"] := [U("09A609C709AF09BC"), U("09A609BF0987")]
Dict["dekano"] := [U("09A609C7099609BE09A809CB")]
Dict["dekben"] := [U("09A609C7099609AC09C709A8")]
Dict["dekbo"] := [U("09A609C7099609AC09CB")]
Dict["dekbona"] := [U("09A609C7099609AC09CB09A809BE")]
Dict["dekche"] := [U("09A609C70996099B09C7")]
Dict["dekchi"] := [U("09A609C70996099B09BF")]
Dict["dekcho"] := [U("09A609C70996099B09CB")]
Dict["deke"] := [U("09A609C7099609C7"), U("09A609C7099609BF")]
Dict["dekechhe"] := [U("09A609C7099609C7099B09C7")]
Dict["dekechi"] := [U("09A609C7099609C7099B09BF")]
Dict["dekecho"] := [U("09A609C7099609C7099B09CB")]
Dict["dekhano"] := [U("09A609C7099609BE09A809CB")]
Dict["dekhanw"] := [U("09A609C7099609BE09A809CB")]
Dict["dekhben"] := [U("09A609C7099609AC09C709A8")]
Dict["dekhbo"] := [U("09A609C7099609AC09CB")]
Dict["dekhbona"] := [U("09A609C7099609AC09CB09A809BE")]
Dict["dekhbw"] := [U("09A609C7099609AC09CB")]
Dict["dekhce"] := [U("09A609C70996099B09C7")]
Dict["dekhche"] := [U("09A609C70996099B09C7")]
Dict["dekhchi"] := [U("09A609C70996099B09BF")]
Dict["dekhcho"] := [U("09A609C70996099B09CB")]
Dict["dekhchw"] := [U("09A609C70996099B09CB")]
Dict["dekhchy"] := [U("09A609C70996099B09BF")]
Dict["dekhci"] := [U("09A609C70996099B09BF")]
Dict["dekhco"] := [U("09A609C70996099B09CB")]
Dict["dekhe"] := [U("09A609C7099609C7")]
Dict["dekheche"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhechhe"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhechi"] := [U("09A609C7099609C7099B09BF")]
Dict["dekhecho"] := [U("09A609C7099609C7099B09CB")]
Dict["dekhechw"] := [U("09A609C7099609C7099B09CB")]
Dict["dekhechy"] := [U("09A609C7099609C7099B09BF")]
Dict["dekheci"] := [U("09A609C7099609C7099B09BF")]
Dict["dekheco"] := [U("09A609C7099609C7099B09CB")]
Dict["dekhi"] := [U("09A609C7099609BF")]
Dict["dekhia"] := [U("09A609C7099609C7")]
Dict["dekho"] := [U("09A609C7099609CB")]
Dict["dekhte"] := [U("09A609C7099609A409C7")]
Dict["dekhun"] := [U("09A609C7099609C109A8")]
Dict["dekhw"] := [U("09A609C7099609CB")]
Dict["dekhy"] := [U("09A609C7099609BF")]
Dict["deki"] := [U("09A609C7099609BF")]
Dict["deko"] := [U("09A609C7099609CB")]
Dict["dekte"] := [U("09A609C7099609A409C7")]
Dict["dekun"] := [U("09A609C7099609C109A8")]
Dict["delibhery"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["deliveri"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["delivery"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["deri"] := [U("09A609C709B009BF")]
Dict["derite"] := [U("09A609C709B009BF09A409C7")]
Dict["des"] := [U("09A609C709B6")]
Dict["desh"] := [U("09A609C709B6")]
Dict["deshign"] := [U("09A109BF099C09BE098709A8")]
Dict["design"] := [U("09A109BF099C09BE098709A8")]
Dict["dey"] := [U("09A609C709AF09BC")]
Dict["dhaka"] := [U("09A209BE099509BE")]
Dict["dhire"] := [U("09A709C009B009C7")]
Dict["dhone"] := [U("09A709A809C7")]
Dict["dhonnobad"] := [U("09A709A809CD09AF09AC09BE09A6")]
Dict["dhonobad"] := [U("09A709A809CD09AF09AC09BE09A6")]
Dict["dhushor"] := [U("09A709C209B809B0")]
Dict["dhusor"] := [U("09A709C209B809B0")]
Dict["dia"] := [U("09A609BF09AF09BC09C7")]
Dict["dibe"] := [U("09A609BF09AC09C7")]
Dict["dibo"] := [U("09A609BF09AC09CB")]
Dict["dibw"] := [U("09A609BF09AC09CB")]
Dict["diia"] := [U("09A609BF09AF09BC09C7")]
Dict["dim"] := [U("09A109BF09AE")]
Dict["din"] := [U("09A609BF09A8")]
Dict["dire"] := [U("09A709C009B009C7")]
Dict["discount"] := [U("09A109BF09B8099509BE098909A809CD099F")]
Dict["dishcount"] := [U("09A109BF09B8099509BE098909A809CD099F")]
Dict["dishplay"] := [U("09A109BF09B809AA09CD09B209C7")]
Dict["displai"] := [U("09A109BF09B809AA09CD09B209C7")]
Dict["display"] := [U("09A109BF09B809AA09CD09B209C7")]
Dict["dite"] := [U("09A609BF09A409C7")]
Dict["ditiyo"] := [U("09A609CD09AC09BF09A409C009AF09BC")]
Dict["ditiyw"] := [U("09A609CD09AC09BF09A409C009AF09BC")]
Dict["diya"] := [U("09A609BF09AF09BC09C7")]
Dict["diye"] := [U("09A609BF09AF09BC09C7")]
Dict["dkbo"] := [U("09A609C7099609AC09CB")]
Dict["dkhbo"] := [U("09A609C7099609AC09CB")]
Dict["dkhbw"] := [U("09A609C7099609AC09CB")]
Dict["dkhi"] := [U("09A609C7099609BF")]
Dict["dkhte"] := [U("09A609C7099609A409C7")]
Dict["dkhy"] := [U("09A609C7099609BF")]
Dict["dki"] := [U("09A609C7099609BF")]
Dict["dkte"] := [U("09A609C7099609A409C7")]
Dict["doctor"] := [U("09A109BE099509CD09A409BE09B0")]
Dict["document"] := [U("09A1099509C109AE09C709A809CD099F")]
Dict["doi"] := [U("09A60987")]
Dict["dokan"] := [U("09A609CB099509BE09A8")]
Dict["done"] := [U("09A109BE09A8")]
Dict["donnobad"] := [U("09A709A809CD09AF09AC09BE09A6")]
Dict["dor"] := [U("09A609B0")]
Dict["dordam"] := [U("09A609B009A609BE09AE")]
Dict["dorja"] := [U("09A609B0099C09BE")]
Dict["dorza"] := [U("09A609B0099C09BE")]
Dict["dos"] := [U("09A609B6")]
Dict["dosh"] := [U("09A609B6")]
Dict["dourai"] := [U("09A609CC09A109BC09BE0987")]
Dict["dourano"] := [U("09A609CC09A109BC09BE09A809CB")]
Dict["douranw"] := [U("09A609CC09A109BC09BE09A809CB")]
Dict["dourate"] := [U("09A609CC09A109BC09BE09A409C7")]
Dict["douray"] := [U("09A609CC09A109BC09BE0987")]
Dict["download"] := [U("09A109BE098909A809B209CB09A1")]
Dict["doy"] := [U("09A60987")]
Dict["doya"] := [U("09A609AF09BC09BE")]
Dict["druto"] := [U("09A609CD09B009C109A4")]
Dict["drutw"] := [U("09A609CD09B009C109A4")]
Dict["dua"] := [U("09A609CB09AF09BC09BE")]
Dict["dubar"] := [U("09A609C109AC09BE09B0")]
Dict["dud"] := [U("09A609C109A7")]
Dict["dudh"] := [U("09A609C109A7")]
Dict["dui"] := [U("09A609C10987")]
Dict["dukhi"] := [U("09A609C10983099609C0")]
Dict["dukho"] := [U("09A609C109830996")]
Dict["dukkhi"] := [U("09A609C10983099609C0")]
Dict["dukkho"] := [U("09A609C109830996")]
Dict["dukkhw"] := [U("09A609C109830996")]
Dict["dukkhy"] := [U("09A609C10983099609C0")]
Dict["dukki"] := [U("09A609C10983099609C0")]
Dict["dukko"] := [U("09A609C109830996")]
Dict["dupur"] := [U("09A609C109AA09C109B0")]
Dict["durbol"] := [U("09A609C109B009CD09AC09B2")]
Dict["dure"] := [U("09A609C209B009C7")]
Dict["dusor"] := [U("09A709C209B809B0")]
Dict["duy"] := [U("09A609C10987")]
Dict["earfone"] := [U("098709AF09BC09BE09B009AB09CB09A8")]
Dict["earphone"] := [U("098709AF09BC09BE09B009AB09CB09A8")]
Dict["ebhabe"] := [U("098F09AD09BE09AC09C7")]
Dict["ebong"] := [U("098F09AC0982")]
Dict["edike"] := [U("098F09A609BF099509C7")]
Dict["egaro"] := [U("098F099709BE09B009CB")]
Dict["egarw"] := [U("098F099709BE09B009CB")]
Dict["egula"] := [U("098F099709C109B209BE")]
Dict["egulo"] := [U("098F099709C109B209CB")]
Dict["ei"] := [U("098F0987")]
Dict["eibhabe"] := [U("098F098709AD09BE09AC09C7")]
Dict["eid"] := [U("098809A6")]
Dict["eidik"] := [U("098F098709A609BF0995")]
Dict["eigula"] := [U("098F0987099709C109B209BE")]
Dict["eigulo"] := [U("098F0987099709C109B209CB")]
Dict["eijonno"] := [U("098F0987099C09A809CD09AF")]
Dict["eikhan"] := [U("098F0987099609BE09A8")]
Dict["eikhane"] := [U("098F0987099609BE09A809C7")]
Dict["eipash"] := [U("098F098709AA09BE09B6")]
Dict["eisob"] := [U("098F098709B809AC")]
Dict["eita"] := [U("098F0987099F09BE")]
Dict["eituku"] := [U("098F0987099F09C1099509C1")]
Dict["ejonno"] := [U("098F099C09A809CD09AF")]
Dict["ek"] := [U("098F0995")]
Dict["ekane"] := [U("098F099609BE09A809C7")]
Dict["ekbar"] := [U("098F099509AC09BE09B0")]
Dict["ekbare"] := [U("098F099509AC09BE09B009C7")]
Dict["ekhane"] := [U("098F099609BE09A809C7")]
Dict["ekhn"] := [U("098F099609A8")]
Dict["ekhon"] := [U("098F099609A8")]
Dict["ekhoni"] := [U("098F099609A80987")]
Dict["ekhono"] := [U("098F099609A809CB")]
Dict["eki"] := [U("098F09950987")]
Dict["ekjon"] := [U("098F0995099C09A8")]
Dict["ekn"] := [U("098F099609A8")]
Dict["ekoi"] := [U("098F09950987")]
Dict["ekon"] := [U("098F099609A8")]
Dict["ekshathe"] := [U("098F099509B809BE09A509C7")]
Dict["eksho"] := [U("098F099509B609CB")]
Dict["ekshw"] := [U("098F099509B609CB")]
Dict["ekso"] := [U("098F099509B609CB")]
Dict["ektu"] := [U("098F0995099F09C1")]
Dict["ektuku"] := [U("098F0995099F09C1099609BE09A809BF")]
Dict["ekzon"] := [U("098F0995099C09A8")]
Dict["email"] := [U("098709AE09C7098709B2")]
Dict["emon"] := [U("098F09AE09A8")]
Dict["epashe"] := [U("098F09AA09BE09B609C7")]
Dict["er"] := [U("098F09B0")]
Dict["eror"] := [U("098F09B009B0")]
Dict["error"] := [U("098F09B009B0")]
Dict["ese"] := [U("098F09B809C7")]
Dict["esece"] := [U("098F09B809C7099B09C7")]
Dict["eseche"] := [U("098F09B809C7099B09C7")]
Dict["eshe"] := [U("098F09B809C7")]
Dict["eshece"] := [U("098F09B809C7099B09C7")]
Dict["esheche"] := [U("098F09B809C7099B09C7")]
Dict["esia"] := [U("098F09B809C7")]
Dict["esob"] := [U("098F09B809AC")]
Dict["eta"] := [U("098F099F09BE")]
Dict["etai"] := [U("098F099F09BE0987")]
Dict["etobar"] := [U("098F09A409AC09BE09B0")]
Dict["etodin"] := [U("098F09A409A609BF09A8")]
Dict["etokhon"] := [U("098F09A4099509CD09B709A3")]
Dict["etokichu"] := [U("098F09A4099509BF099B09C1")]
Dict["etota"] := [U("098F09A4099F09BE")]
Dict["etotuku"] := [U("098F09A4099F09C1099509C1")]
Dict["excange"] := [U("098F099509CD09B8099A09C7099E09CD099C")]
Dict["exchange"] := [U("098F099509CD09B8099A09C7099E09CD099C")]
Dict["facebook"] := [U("09AB09C709B809AC09C10995")]
Dict["facebuk"] := [U("09AB09C709B809AC09C10995")]
Dict["factori"] := [U("09AB09CD09AF09BE099509CD099F09B009BF")]
Dict["factory"] := [U("09AB09CD09AF09BE099509CD099F09B009BF")]
Dict["fake"] := [U("09AB09C70995")]
Dict["faltu"] := [U("09AB09BE09B209A409C1")]
Dict["fan"] := [U("09AB09CD09AF09BE09A8")]
Dict["farmacy"] := [U("09AB09BE09B009CD09AE09C709B809BF")]
Dict["fasht"] := [U("09AB09BE09B809CD099F")]
Dict["fast"] := [U("09AB09BE09B809CD099F")]
Dict["fb"] := [U("09AB09C709B809AC09C10995")]
Dict["ferri"] := [U("09AB09C709B009BF")]
Dict["ferry"] := [U("09AB09C709B009BF")]
Dict["fery"] := [U("09AB09C709B009BF")]
Dict["file"] := [U("09AB09BE098709B2")]
Dict["firbo"] := [U("09AB09BF09B009AC09CB")]
Dict["firbw"] := [U("09AB09BF09B009AC09CB")]
Dict["fire"] := [U("09AB09BF09B009C7")]
Dict["firte"] := [U("09AB09BF09B009A409C7")]
Dict["fix"] := [U("09AB09BF099509CD09B8")]
Dict["flight"] := [U("09AB09CD09B209BE0987099F")]
Dict["fn"] := [U("09AB09CB09A8")]
Dict["fol"] := [U("09AB09B2")]
Dict["folder"] := [U("09AB09CB09B209CD09A109BE09B0")]
Dict["folloo"] := [U("09AB09B209CB")]
Dict["follow"] := [U("09AB09B209CB")]
Dict["follower"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["folow"] := [U("09AB09B209CB")]
Dict["folower"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["fone"] := [U("09AB09CB09A8")]
Dict["footbal"] := [U("09AB09C1099F09AC09B2")]
Dict["football"] := [U("09AB09C1099F09AC09B2")]
Dict["foto"] := [U("099B09AC09BF")]
Dict["fotocopy"] := [U("09AB099F09CB099509AA09BF")]
Dict["free"] := [U("09AB09CD09B009BF")]
Dict["fri"] := [U("09AB09CD09B009BF")]
Dict["fridai"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["friday"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["fridge"] := [U("09AB09CD09B009BF099C")]
Dict["frnd"] := [U("09AC09A809CD09A709C1")]
Dict["fufu"] := [U("09AB09C109AB09C1")]
Dict["ful"] := [U("09AB09C109B2")]
Dict["futball"] := [U("09AB09C1099F09AC09B2")]
Dict["gaan"] := [U("099709BE09A8")]
Dict["gac"] := [U("099709BE099B")]
Dict["gach"] := [U("099709BE099B")]
Dict["gai"] := [U("099709BE0987")]
Dict["gaibo"] := [U("099709BE098709AC09CB")]
Dict["gaibw"] := [U("099709BE098709AC09CB")]
Dict["gaite"] := [U("099709BE098709A409C7")]
Dict["galery"] := [U("099709CD09AF09BE09B209BE09B009BF")]
Dict["galleri"] := [U("099709CD09AF09BE09B209BE09B009BF")]
Dict["gallery"] := [U("099709CD09AF09BE09B209BE09B009BF")]
Dict["gao"] := [U("099709BE0993")]
Dict["gari"] := [U("099709BE09A109BC09BF")]
Dict["gary"] := [U("099709BE09A109BC09BF")]
Dict["gas"] := [U("099709CD09AF09BE09B8")]
Dict["gash"] := [U("099709CD09AF09BE09B8")]
Dict["gate"] := [U("099709C7099F")]
Dict["gaw"] := [U("099709BE0993")]
Dict["gay"] := [U("099709BE09AF09BC")]
Dict["gb"] := [U("099C09BF09AC09BF")]
Dict["gece"] := [U("099709C7099B09C7")]
Dict["geche"] := [U("099709C7099B09C7")]
Dict["ghar"] := [U("099809B0")]
Dict["ghee"] := [U("099809BF")]
Dict["ghi"] := [U("099809BF")]
Dict["ghum"] := [U("099809C109AE")]
Dict["ghumabo"] := [U("099809C109AE09BE09AC09CB")]
Dict["ghumabw"] := [U("099809C109AE09BE09AC09CB")]
Dict["ghumai"] := [U("099809C109AE09BE0987")]
Dict["ghumao"] := [U("099809C109AE09BE0993")]
Dict["ghumate"] := [U("099809C109AE09BE09A409C7")]
Dict["ghumaw"] := [U("099809C109AE09BE0993")]
Dict["ghumay"] := [U("099809C109AE09BE09AF09BC")]
Dict["gia"] := [U("099709BF09AF09BC09C7")]
Dict["giia"] := [U("099709BF09AF09BC09C7")]
Dict["giya"] := [U("099709BF09AF09BC09C7")]
Dict["giye"] := [U("099709BF09AF09BC09C7")]
Dict["giyeche"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["giyechhe"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["giyechi"] := [U("099709BF09AF09BC09C7099B09BF")]
Dict["giyecho"] := [U("099709BF09AF09BC09C7099B09CB")]
Dict["giyechw"] := [U("099709BF09AF09BC09C7099B09CB")]
Dict["giyechy"] := [U("099709BF09AF09BC09C7099B09BF")]
Dict["giyeci"] := [U("099709BF09AF09BC09C7099B09BF")]
Dict["giyeco"] := [U("099709BF09AF09BC09C7099B09CB")]
Dict["glas"] := [U("099709CD09B209BE09B8")]
Dict["glashs"] := [U("099709CD09B209BE09B8")]
Dict["glass"] := [U("099709CD09B209BE09B8")]
Dict["gmail"] := [U("099C09BF09AE09C7098709B2")]
Dict["godown"] := [U("099709C109A609BE09AE")]
Dict["golapi"] := [U("099709CB09B209BE09AA09BF")]
Dict["golapy"] := [U("099709CB09B209BE09AA09BF")]
Dict["golpo"] := [U("099709B209CD09AA")]
Dict["golpw"] := [U("099709B209CD09AA")]
Dict["gonit"] := [U("099709A309BF09A4")]
Dict["good"] := [U("099709C109A1")]
Dict["google"] := [U("099709C1099709B2")]
Dict["gorom"] := [U("099709B009AE")]
Dict["gorur"] := [U("099709B009C109B0")]
Dict["gotokal"] := [U("099709A4099509BE09B2")]
Dict["gram"] := [U("099709CD09B009BE09AE")]
Dict["grishmo"] := [U("099709CD09B009C009B709CD09AE")]
Dict["grishmw"] := [U("099709CD09B009C009B709CD09AE")]
Dict["grismo"] := [U("099709CD09B009C009B709CD09AE")]
Dict["group"] := [U("099709CD09B009C109AA")]
Dict["gud"] := [U("099709C109A1")]
Dict["gudam"] := [U("099709C109A609BE09AE")]
Dict["gugle"] := [U("099709C1099709B2")]
Dict["gyan"] := [U("099C09CD099E09BE09A8")]
Dict["gyani"] := [U("099C09CD099E09BE09A809C0")]
Dict["gyany"] := [U("099C09CD099E09BE09A809C0")]
Dict["ha"] := [U("09B909CD09AF09BE0981")]
Dict["haat"] := [U("09B909BE09A4")]
Dict["hadis"] := [U("09B909BE09A609BF09B8")]
Dict["hadish"] := [U("09B909BE09A609BF09B8")]
Dict["hajar"] := [U("09B909BE099C09BE09B0")]
Dict["hang"] := [U("09B909CD09AF09BE0982")]
Dict["hasbo"] := [U("09B909BE09B809AC09CB")]
Dict["hasbw"] := [U("09B909BE09B809AC09CB")]
Dict["hashbo"] := [U("09B909BE09B809AC09CB")]
Dict["hashi"] := [U("09B909BE09B809BF")]
Dict["hashte"] := [U("09B909BE09B809A409C7")]
Dict["hashy"] := [U("09B909BE09B809BF")]
Dict["hasi"] := [U("09B909BE09B809BF")]
Dict["haste"] := [U("09B909BE09B809A409C7")]
Dict["hata"] := [U("09B909BE0981099F09BE")]
Dict["hatbo"] := [U("09B909BE0981099F09AC09CB")]
Dict["hatbw"] := [U("09B909BE0981099F09AC09CB")]
Dict["hate"] := [U("09B909BE0981099F09C7")]
Dict["hati"] := [U("09B909BE0981099F09BF")]
Dict["hatte"] := [U("09B909BE0981099F09A409C7")]
Dict["haty"] := [U("09B909BE0981099F09BF")]
Dict["hazar"] := [U("09B909BE099C09BE09B0")]
Dict["hbe"] := [U("09B909AC09C7")]
Dict["headfone"] := [U("09B909C709A109AB09CB09A8")]
Dict["headphone"] := [U("09B909C709A109AB09CB09A8")]
Dict["hello"] := [U("09B909CD09AF09BE09B209CB")]
Dict["hellw"] := [U("09B909CD09AF09BE09B209CB")]
Dict["helo"] := [U("09B909CD09AF09BE09B209CB")]
Dict["hemonto"] := [U("09B909C709AE09A809CD09A4")]
Dict["hemontw"] := [U("09B909C709AE09A809CD09A4")]
Dict["hi"] := [U("09B909BE0987")]
Dict["hm"] := [U("09B909C109AE")]
Dict["hmm"] := [U("09B909C109AE")]
Dict["hobe"] := [U("09B909AC09C7")]
Dict["hobena"] := [U("09B909AC09C709A809BE")]
Dict["hoche"] := [U("09B9099A09CD099B09C7")]
Dict["hochhe"] := [U("09B9099A09CD099B09C7")]
Dict["hoi"] := [U("09B909AF09BC"), U("09B90987")]
Dict["hoia"] := [U("09B909AF09BC09C7")]
Dict["hoice"] := [U("09B90987099B09C7")]
Dict["hoiche"] := [U("09B90987099B09C7")]
Dict["hoito"] := [U("09B909AF09BC09A409CB")]
Dict["hoitw"] := [U("09B909AF09BC09A409CB")]
Dict["holidai"] := [U("099B09C1099F09BF")]
Dict["holiday"] := [U("099B09C1099F09BF")]
Dict["holo"] := [U("09B909B209CB")]
Dict["holud"] := [U("09B909B209C109A6")]
Dict["holw"] := [U("09B909B209CB")]
Dict["hoshpital"] := [U("09B909BE09B809AA09BE09A409BE09B2")]
Dict["hospital"] := [U("09B909BE09B809AA09BE09A409BE09B2")]
Dict["hotath"] := [U("09B909A009BE09CE")]
Dict["hote"] := [U("09B909A409C7")]
Dict["hotel"] := [U("09B909CB099F09C709B2")]
Dict["hothat"] := [U("09B909A009BE09CE")]
Dict["howa"] := [U("09B9099309AF09BC09BE")]
Dict["hoy"] := [U("09B909AF09BC")]
Dict["hoya"] := [U("09B909AF09BC09C7")]
Dict["hoye"] := [U("09B909AF09BC09C7")]
Dict["hoyeche"] := [U("09B909AF09BC09C7099B09C7")]
Dict["hoyechhe"] := [U("09B909AF09BC09C7099B09C7")]
Dict["hoyechi"] := [U("09B909AF09BC09C7099B09BF")]
Dict["hoyecho"] := [U("09B909AF09BC09C7099B09CB")]
Dict["hoyechw"] := [U("09B909AF09BC09C7099B09CB")]
Dict["hoyechy"] := [U("09B909AF09BC09C7099B09BF")]
Dict["hoyeci"] := [U("09B909AF09BC09C7099B09BF")]
Dict["hoyeco"] := [U("09B909AF09BC09C7099B09CB")]
Dict["hoyto"] := [U("09B909AF09BC09A409CB")]
Dict["hoytw"] := [U("09B909AF09BC09A409CB")]
Dict["hridoi"] := [U("09B909C309A609AF09BC")]
Dict["hridoy"] := [U("09B909C309A609AF09BC")]
Dict["hujur"] := [U("09B909C1099C09C109B0")]
Dict["huzur"] := [U("09B909C1099C09C109B0")]
Dict["hyan"] := [U("09B909CD09AF09BE0981")]
Dict["id"] := [U("0986098709A109BF")]
Dict["ig"] := [U("098709A809B809CD099F09BE099709CD09B009BE09AE")]
Dict["image"] := [U("098709AE09C7099C")]
Dict["imam"] := [U("098709AE09BE09AE")]
Dict["inbhite"] := [U("098709A809AD09BE0987099F")]
Dict["inbox"] := [U("098709A809AC099509CD09B8")]
Dict["income"] := [U("098709A8099509BE09AE")]
Dict["insallah"] := [U("098709A809B609BE098609B209CD09B209BE09B9")]
Dict["inshalah"] := [U("098709A809B609BE098609B209CD09B209BE09B9")]
Dict["inshallah"] := [U("098709A809B609BE098609B209CD09B209BE09B9")]
Dict["inshta"] := [U("098709A809B809CD099F09BE099709CD09B009BE09AE")]
Dict["inshtagram"] := [U("098709A809B809CD099F09BE099709CD09B009BE09AE")]
Dict["inshtall"] := [U("098709A809B809CD099F09B2")]
Dict["insta"] := [U("098709A809B809CD099F09BE099709CD09B009BE09AE")]
Dict["instagram"] := [U("098709A809B809CD099F09BE099709CD09B009BE09AE")]
Dict["instal"] := [U("098709A809B809CD099F09B2")]
Dict["install"] := [U("098709A809B809CD099F09B2")]
Dict["interesht"] := [U("098709A809CD099F09BE09B009C709B809CD099F")]
Dict["interest"] := [U("098709A809CD099F09BE09B009C709B809CD099F")]
Dict["internet"] := [U("098709A809CD099F09BE09B009A809C7099F")]
Dict["invite"] := [U("098709A809AD09BE0987099F")]
Dict["itihas"] := [U("098709A409BF09B909BE09B8")]
Dict["itihash"] := [U("098709A409BF09B909BE09B8")]
Dict["jabe"] := [U("09AF09BE09AC09C7")]
Dict["jaben"] := [U("09AF09BE09AC09C709A8")]
Dict["jabena"] := [U("09AF09BE09AC09C709A8002009A809BE")]
Dict["jabenna"] := [U("09AF09BE09AC09C709A8002009A809BE")]
Dict["jabo"] := [U("09AF09BE09AC09CB")]
Dict["jabona"] := [U("09AF09BE09AC09CB09A809BE")]
Dict["jabw"] := [U("09AF09BE09AC09CB")]
Dict["jache"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jachhe"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jachhi"] := [U("09AF09BE099A09CD099B09BF")]
Dict["jachho"] := [U("09AF09BE099A09CD099B09CB")]
Dict["jachhw"] := [U("09AF09BE099A09CD099B09CB")]
Dict["jachhy"] := [U("09AF09BE099A09CD099B09BF")]
Dict["jachi"] := [U("09AF09BE099A09CD099B09BF")]
Dict["jacho"] := [U("09AF09BE099A09CD099B09CB")]
Dict["jagte"] := [U("099C09BE099709A409C7")]
Dict["jai"] := [U("09AF09BE0987"), U("09AF09BE09AF09BC")]
Dict["jaia"] := [U("09AF09C709AF09BC09C7")]
Dict["jajakallah"] := [U("099C09BE09AF09BE099509BE09B209CD09B209BE09B9")]
Dict["jake"] := [U("09AF09BE099509C7")]
Dict["jamai"] := [U("099C09BE09AE09BE0987")]
Dict["jamay"] := [U("099C09BE09AE09BE0987")]
Dict["jan"] := [U("09AF09BE09A8")]
Dict["janala"] := [U("099C09BE09A809BE09B209BE")]
Dict["janben"] := [U("099C09BE09A809AC09C709A8")]
Dict["janbo"] := [U("099C09BE09A809AC09CB")]
Dict["janbw"] := [U("099C09BE09A809AC09CB")]
Dict["janchi"] := [U("099C09BE09A8099B09BF")]
Dict["janchy"] := [U("099C09BE09A8099B09BF")]
Dict["janci"] := [U("099C09BE09A8099B09BF")]
Dict["jane"] := [U("099C09BE09A809C7")]
Dict["janen"] := [U("099C09BE09A809C709A8")]
Dict["jani"] := [U("099C09BE09A809BF")]
Dict["jania"] := [U("099C09C709A809C7")]
Dict["jano"] := [U("099C09BE09A809CB")]
Dict["jante"] := [U("099C09BE09A809A409C7")]
Dict["janw"] := [U("099C09BE09A809CB")]
Dict["jany"] := [U("099C09BE09A809BF")]
Dict["jao"] := [U("09AF09BE0993")]
Dict["jara"] := [U("09AF09BE09B009BE")]
Dict["jaw"] := [U("09AF09BE0993")]
Dict["jay"] := [U("09AF09BE09AF09BC")]
Dict["jbe"] := [U("09AF09BE09AC09C7")]
Dict["jbo"] := [U("09AF09BE09AC09CB")]
Dict["jbw"] := [U("09AF09BE09AC09CB")]
Dict["jege"] := [U("099C09C7099709C7")]
Dict["jeia"] := [U("09AF09C709AF09BC09C7")]
Dict["jemon"] := [U("09AF09C709AE09A8")]
Dict["jene"] := [U("099C09C709A809C7")]
Dict["jete"] := [U("09AF09C709A409C7")]
Dict["jeya"] := [U("09AF09C709AF09BC09C7")]
Dict["jeye"] := [U("09AF09C709AF09BC09C7")]
Dict["jilapi"] := [U("099C09BF09B209BE09AA09BF")]
Dict["jilapy"] := [U("099C09BF09B209BE09AA09BF")]
Dict["jinis"] := [U("099C09BF09A809BF09B8")]
Dict["jinish"] := [U("099C09BF09A809BF09B8")]
Dict["jip"] := [U("099C09BF09AA")]
Dict["jira"] := [U("099C09BF09B009BE")]
Dict["jnbo"] := [U("099C09BE09A809AC09CB")]
Dict["jnbw"] := [U("099C09BE09A809AC09CB")]
Dict["jni"] := [U("099C09BE09A809BF")]
Dict["jnina"] := [U("099C09BE09A809BF09A809BE")]
Dict["jny"] := [U("099C09BE09A809BF")]
Dict["jodi"] := [U("09AF09A609BF")]
Dict["jodio"] := [U("09AF09A609BF0993")]
Dict["join"] := [U("099C09AF09BC09C709A8")]
Dict["jonno"] := [U("099C09A809CD09AF")]
Dict["jonnw"] := [U("099C09A809CD09AF")]
Dict["jono"] := [U("099C09A809CD09AF")]
Dict["jonogon"] := [U("099C09A8099709A3")]
Dict["jore"] := [U("099C09CB09B009C7")]
Dict["juddho"] := [U("09AF09C109A609CD09A7")]
Dict["juddhw"] := [U("09AF09C109A609CD09A7")]
Dict["juddo"] := [U("09AF09C109A609CD09A7")]
Dict["judho"] := [U("09AF09C109A609CD09A7")]
Dict["kaan"] := [U("099509BE09A8")]
Dict["kabar"] := [U("099609BE09AC09BE09B0")]
Dict["kaben"] := [U("099609BE09AC09C709A8")]
Dict["kabo"] := [U("099609BE09AC09CB")]
Dict["kabona"] := [U("099609BE09AC09CB09A809BE")]
Dict["kace"] := [U("099509BE099B09C7")]
Dict["kache"] := [U("099509BE099B09C7")]
Dict["kachhe"] := [U("099609BE099A09CD099B09C7")]
Dict["kachhi"] := [U("099609BE099A09CD099B09BF")]
Dict["kagoj"] := [U("099509BE0997099C")]
Dict["kagoz"] := [U("099509BE0997099C")]
Dict["kai"] := [U("099609BE0987")]
Dict["kair"] := [U("099609BE09AF09BC09C709B0")]
Dict["kaj"] := [U("099509BE099C")]
Dict["kake"] := [U("099509BE099509C7")]
Dict["kala"] := [U("099609BE09B209BE")]
Dict["kalke"] := [U("099509BE09B2099509C7")]
Dict["kalo"] := [U("099509BE09B209CB")]
Dict["kalw"] := [U("099509BE09B209CB")]
Dict["kan"] := [U("099609BE09A8")]
Dict["kana"] := [U("099509BE09A809CD09A809BE")]
Dict["kandbo"] := [U("099509BE098109A609AC09CB")]
Dict["kandbw"] := [U("099509BE098109A609AC09CB")]
Dict["kande"] := [U("099509BE098109A609C7")]
Dict["kandte"] := [U("099509BE098109A609A409C7")]
Dict["kanna"] := [U("099509BE09A809CD09A809BE")]
Dict["kao"] := [U("099509C70989")]
Dict["kaowa"] := [U("099609BE099309AF09BC09BE")]
Dict["kar"] := [U("099509BE09B0")]
Dict["karap"] := [U("099609BE09B009BE09AA")]
Dict["karon"] := [U("099509BE09B009A3")]
Dict["kashi"] := [U("099609BE09B809BF")]
Dict["kasi"] := [U("099609BE09B809BF")]
Dict["kata"] := [U("099609BE09A409BE")]
Dict["katal"] := [U("099509BE098109A009BE09B2")]
Dict["kathal"] := [U("099509BE098109A009BE09B2")]
Dict["kay"] := [U("099609BE09AF09BC")]
Dict["kaz"] := [U("099509BE099C")]
Dict["kbo"] := [U("099609BE09AC09CB")]
Dict["ke"] := [U("099509C7")]
Dict["kejur"] := [U("099609C7099C09C109B0")]
Dict["kela"] := [U("099609C709B209BE")]
Dict["kelbo"] := [U("099609C709B209AC09CB")]
Dict["kele"] := [U("099609C709B209C7")]
Dict["keli"] := [U("099609C709B209BF")]
Dict["kelo"] := [U("099609C709B209CB")]
Dict["kelte"] := [U("099609C709B209A409C7")]
Dict["kemne"] := [U("099509C709AE09A809C7")]
Dict["kemon"] := [U("099509C709AE09A8")]
Dict["keno"] := [U("099509C709A8")]
Dict["kenw"] := [U("099509C709A8")]
Dict["keo"] := [U("099509C70989")]
Dict["kete"] := [U("099609C709A409C7")]
Dict["keu"] := [U("099509C70989")]
Dict["keuna"] := [U("099509C70989002009A809BE")]
Dict["kew"] := [U("099509C70989")]
Dict["keyboard"] := [U("099509BF09AC09CB09B009CD09A1")]
Dict["keyechhe"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["keyechi"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["keyecho"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["khabar"] := [U("099609BE09AC09BE09B0")]
Dict["khaben"] := [U("099609BE09AC09C709A8")]
Dict["khabo"] := [U("099609BE09AC09CB")]
Dict["khabona"] := [U("099609BE09AC09CB09A809BE")]
Dict["khabw"] := [U("099609BE09AC09CB")]
Dict["khache"] := [U("099609BE099A09CD099B09C7")]
Dict["khachhe"] := [U("099609BE099A09CD099B09C7")]
Dict["khachhi"] := [U("099609BE099A09CD099B09BF")]
Dict["khachhy"] := [U("099609BE099A09CD099B09BF")]
Dict["khachi"] := [U("099609BE099A09CD099B09BF")]
Dict["khai"] := [U("099609BE0987")]
Dict["khaia"] := [U("099609C709AF09BC09C7")]
Dict["khair"] := [U("099609BE09AF09BC09C709B0")]
Dict["khala"] := [U("099609BE09B209BE")]
Dict["khan"] := [U("099609BE09A8")]
Dict["khao"] := [U("099609BE0993")]
Dict["khaowa"] := [U("099609BE099309AF09BC09BE")]
Dict["kharap"] := [U("099609BE09B009BE09AA")]
Dict["khashi"] := [U("099609BE09B809BF")]
Dict["khashy"] := [U("099609BE09B809BF")]
Dict["khasi"] := [U("099609BE09B809BF")]
Dict["khata"] := [U("099609BE09A409BE")]
Dict["khaw"] := [U("099609BE0993")]
Dict["khay"] := [U("099609BE09AF09BC")]
Dict["khbo"] := [U("099609BE09AC09CB")]
Dict["khbw"] := [U("099609BE09AC09CB")]
Dict["kheia"] := [U("099609C709AF09BC09C7")]
Dict["khejur"] := [U("099609C7099C09C109B0")]
Dict["khela"] := [U("099609C709B209BE")]
Dict["khelbo"] := [U("099609C709B209AC09CB")]
Dict["khelbw"] := [U("099609C709B209AC09CB")]
Dict["khele"] := [U("099609C709B209C7")]
Dict["kheli"] := [U("099609C709B209BF")]
Dict["khelo"] := [U("099609C709B209CB")]
Dict["khelte"] := [U("099609C709B209A409C7")]
Dict["khelw"] := [U("099609C709B209CB")]
Dict["khely"] := [U("099609C709B209BF")]
Dict["khete"] := [U("099609C709A409C7")]
Dict["kheya"] := [U("099609C709AF09BC09C7")]
Dict["kheye"] := [U("099609C709AF09BC09C7")]
Dict["kheyeche"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kheyechhe"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kheyechi"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["kheyecho"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["kheyechw"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["kheyechy"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["kheyeci"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["kheyeco"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["khezur"] := [U("099609C7099C09C109B0")]
Dict["khichuri"] := [U("099609BF099A09C109A109BC09BF")]
Dict["khichury"] := [U("099609BF099A09C109A109BC09BF")]
Dict["khicuri"] := [U("099609BF099A09C109A109BC09BF")]
Dict["khobor"] := [U("099609AC09B0")]
Dict["khoma"] := [U("099509CD09B709AE09BE")]
Dict["khorca"] := [U("099609B0099A09BE")]
Dict["khorcha"] := [U("099609B0099A09BE")]
Dict["khoroc"] := [U("099609B0099A")]
Dict["khoroch"] := [U("099609B0099A")]
Dict["khoti"] := [U("099509CD09B709A409BF")]
Dict["khoty"] := [U("099509CD09B709A409BF")]
Dict["khub"] := [U("099609C109AC")]
Dict["khushi"] := [U("099609C109B609BF")]
Dict["khushy"] := [U("099609C109B609BF")]
Dict["khusi"] := [U("099609C109B609BF")]
Dict["ki"] := [U("099509BF"), U("099509C0")]
Dict["kibhabe"] := [U("099509BF09AD09BE09AC09C7")]
Dict["kichu"] := [U("099509BF099B09C1")]
Dict["kichui"] := [U("099509BF099B09C10987")]
Dict["kichuna"] := [U("099509BF099B09C1002009A809BE")]
Dict["kichuri"] := [U("099609BF099A09C109A109BC09BF")]
Dict["kichuy"] := [U("099509BF099B09C10987")]
Dict["kicu"] := [U("099509BF099B09C1")]
Dict["kicui"] := [U("099509BF099B09C10987")]
Dict["kicuna"] := [U("099509BF099B09C1002009A809BE")]
Dict["kinbo"] := [U("099509BF09A809AC09CB")]
Dict["kinbw"] := [U("099509BF09A809AC09CB")]
Dict["kine"] := [U("099509BF09A809C7")]
Dict["kini"] := [U("099509BF09A809BF")]
Dict["kinte"] := [U("099509BF09A809A409C7")]
Dict["kintu"] := [U("099509BF09A809CD09A409C1")]
Dict["kiny"] := [U("099509BF09A809BF")]
Dict["kishti"] := [U("099509BF09B809CD09A409BF")]
Dict["kisti"] := [U("099509BF09B809CD09A409BF")]
Dict["kisty"] := [U("099509BF09B809CD09A409BF")]
Dict["kitcen"] := [U("09B009BE09A809CD09A809BE099809B0")]
Dict["kitchen"] := [U("09B009BE09A809CD09A809BE099809B0")]
Dict["kivabe"] := [U("099509BF09AD09BE09AC09C7")]
Dict["kk"] := [U("0993099509C7")]
Dict["klanti"] := [U("099509CD09B209BE09A809CD09A409BF")]
Dict["klanto"] := [U("099509CD09B209BE09A809CD09A4")]
Dict["klantw"] := [U("099509CD09B209BE09A809CD09A4")]
Dict["klanty"] := [U("099509CD09B209BE09A809CD09A409BF")]
Dict["kmn"] := [U("099509C709AE09A8")]
Dict["kmon"] := [U("099509C709AE09A8")]
Dict["knife"] := [U("099B09C109B009BF")]
Dict["kniphe"] := [U("099B09C109B009BF")]
Dict["kobe"] := [U("099509AC09C7")]
Dict["kobita"] := [U("099509AC09BF09A409BE")]
Dict["kobor"] := [U("099609AC09B0")]
Dict["kokhn"] := [U("0995099609A8")]
Dict["kokhon"] := [U("0995099609A8")]
Dict["kokhono"] := [U("0995099609A809CB")]
Dict["kokhonoi"] := [U("0995099609A809CB0987")]
Dict["kokhonoy"] := [U("0995099609A809CB0987")]
Dict["kokhonw"] := [U("0995099609A809CB")]
Dict["kokn"] := [U("0995099609A8")]
Dict["kokon"] := [U("0995099609A8")]
Dict["kokono"] := [U("0995099609A809CB")]
Dict["kokonoi"] := [U("0995099609A809CB0987")]
Dict["kola"] := [U("099509B209BE")]
Dict["kolom"] := [U("099509B209AE")]
Dict["kom"] := [U("099509AE")]
Dict["koma"] := [U("099509CD09B709AE09BE")]
Dict["komano"] := [U("099509AE09BE09A809CB")]
Dict["komanw"] := [U("099509AE09BE09A809CB")]
Dict["kombe"] := [U("099509AE09AC09C7")]
Dict["komece"] := [U("099509AE09C7099B09C7")]
Dict["komeche"] := [U("099509AE09C7099B09C7")]
Dict["komla"] := [U("099509AE09B209BE")]
Dict["komola"] := [U("099509AE09B209BE")]
Dict["kon"] := [U("099509CB09A8")]
Dict["kora"] := [U("099509B009BE"), U("099509B009C7")]
Dict["korben"] := [U("099509B009AC09C709A8")]
Dict["korbena"] := [U("099509B009AC09C709A8002009A809BE")]
Dict["korbenna"] := [U("099509B009AC09C709A8002009A809BE")]
Dict["korbo"] := [U("099509B009AC09CB")]
Dict["korbona"] := [U("099509B009AC09CB09A809BE")]
Dict["korbw"] := [U("099509B009AC09CB")]
Dict["korce"] := [U("099509B0099B09C7")]
Dict["korcha"] := [U("099609B0099A09BE")]
Dict["korche"] := [U("099509B0099B09C7")]
Dict["korchi"] := [U("099509B0099B09BF")]
Dict["korcho"] := [U("099509B0099B09CB")]
Dict["korchw"] := [U("099509B0099B09CB")]
Dict["korchy"] := [U("099509B0099B09BF")]
Dict["korci"] := [U("099509B0099B09BF")]
Dict["korco"] := [U("099509B0099B09CB")]
Dict["kore"] := [U("099509B009C7")]
Dict["koreche"] := [U("099509B009C7099B09C7")]
Dict["korechhe"] := [U("099509B009C7099B09C7")]
Dict["korechi"] := [U("099509B009C7099B09BF")]
Dict["korecho"] := [U("099509B009C7099B09CB")]
Dict["korechw"] := [U("099509B009C7099B09CB")]
Dict["korechy"] := [U("099509B009C7099B09BF")]
Dict["koreci"] := [U("099509B009C7099B09BF")]
Dict["koreco"] := [U("099509B009C7099B09CB")]
Dict["koren"] := [U("099509B009C709A8")]
Dict["kori"] := [U("099509B009BF")]
Dict["koria"] := [U("099509B009C7")]
Dict["korlam"] := [U("099509B009B209BE09AE")]
Dict["korm"] := [U("099509B009CD09AE")]
Dict["kormo"] := [U("099509B009CD09AE")]
Dict["kormw"] := [U("099509B009CD09AE")]
Dict["koro"] := [U("099509B009CB")]
Dict["koroch"] := [U("099609B0099A")]
Dict["korte"] := [U("099509B009A409C7")]
Dict["korw"] := [U("099509B009CB")]
Dict["kory"] := [U("099509B009BF")]
Dict["koshto"] := [U("099509B709CD099F")]
Dict["kosto"] := [U("099509B709CD099F")]
Dict["kostw"] := [U("099509B709CD099F")]
Dict["kota"] := [U("099509A509BE")]
Dict["kotay"] := [U("099509CB09A509BE09AF09BC")]
Dict["kotha"] := [U("099509A509BE")]
Dict["kothai"] := [U("099509CB09A509BE09AF09BC")]
Dict["kothay"] := [U("099509CB09A509BE09AF09BC")]
Dict["kothin"] := [U("099509A009BF09A8")]
Dict["koti"] := [U("099509CB099F09BF")]
Dict["kotin"] := [U("099509A009BF09A8")]
Dict["koto"] := [U("099509A4")]
Dict["kotw"] := [U("099509A4")]
Dict["koty"] := [U("099509CB099F09BF")]
Dict["krbo"] := [U("099509B009AC09CB")]
Dict["krbw"] := [U("099509B009AC09CB")]
Dict["krchi"] := [U("099509B0099B09BF")]
Dict["krchy"] := [U("099509B0099B09BF")]
Dict["krci"] := [U("099509B0099B09BF")]
Dict["krlam"] := [U("099509B009B209BE09AE")]
Dict["krlo"] := [U("099509B009B209CB")]
Dict["krlw"] := [U("099509B009B209CB")]
Dict["krte"] := [U("099509B009A409C7")]
Dict["kub"] := [U("099609C109AC")]
Dict["kushi"] := [U("099609C109B609BF")]
Dict["kusi"] := [U("099609C109B609BF")]
Dict["labh"] := [U("09B209BE09AD")]
Dict["laf"] := [U("09B209BE09AB")]
Dict["lafano"] := [U("09B209BE09AB09BE09A809CB")]
Dict["lafanw"] := [U("09B209BE09AB09BE09A809CB")]
Dict["lagbe"] := [U("09B209BE099709AC09C7")]
Dict["lagche"] := [U("09B209BE0997099B09C7")]
Dict["lage"] := [U("09B209BE099709C7")]
Dict["laglo"] := [U("09B209BE099709B209CB")]
Dict["lagse"] := [U("09B209BE0997099B09C7")]
Dict["lak"] := [U("09B209BE0996")]
Dict["lakh"] := [U("09B209BE0996")]
Dict["lal"] := [U("09B209BE09B2")]
Dict["laph"] := [U("09B209BE09AB")]
Dict["laphano"] := [U("09B209BE09AB09BE09A809CB")]
Dict["laptop"] := [U("09B209CD09AF09BE09AA099F09AA")]
Dict["late"] := [U("09B209C7099F")]
Dict["launc"] := [U("09B2099E09CD099A")]
Dict["launch"] := [U("09B2099E09CD099A")]
Dict["lav"] := [U("09B209BE09AD")]
Dict["lebu"] := [U("09B209C709AC09C1")]
Dict["libhe"] := [U("09B209BE098709AD")]
Dict["license"] := [U("09B209BE098709B809C709A809CD09B8")]
Dict["licenshe"] := [U("09B209BE098709B809C709A809CD09B8")]
Dict["lichu"] := [U("09B209BF099A09C1")]
Dict["licu"] := [U("09B209BF099A09C1")]
Dict["lift"] := [U("09B209BF09AB099F")]
Dict["light"] := [U("09B209BE0987099F")]
Dict["likben"] := [U("09B209BF099609AC09C709A8")]
Dict["likbo"] := [U("09B209BF099609AC09CB")]
Dict["likche"] := [U("09B209BF0996099B09C7")]
Dict["likchi"] := [U("09B209BF0996099B09BF")]
Dict["like"] := [U("09B209BE09870995")]
Dict["likechhe"] := [U("09B209BF099609C7099B09C7")]
Dict["likechi"] := [U("09B209BF099609C7099B09BF")]
Dict["likecho"] := [U("09B209BF099609C7099B09CB")]
Dict["likhben"] := [U("09B209BF099609AC09C709A8")]
Dict["likhbo"] := [U("09B209BF099609AC09CB")]
Dict["likhbw"] := [U("09B209BF099609AC09CB")]
Dict["likhce"] := [U("09B209BF0996099B09C7")]
Dict["likhche"] := [U("09B209BF0996099B09C7")]
Dict["likhchi"] := [U("09B209BF0996099B09BF")]
Dict["likhchy"] := [U("09B209BF0996099B09BF")]
Dict["likhci"] := [U("09B209BF0996099B09BF")]
Dict["likhe"] := [U("09B209BF099609C7")]
Dict["likheche"] := [U("09B209BF099609C7099B09C7")]
Dict["likhechhe"] := [U("09B209BF099609C7099B09C7")]
Dict["likhechi"] := [U("09B209BF099609C7099B09BF")]
Dict["likhecho"] := [U("09B209BF099609C7099B09CB")]
Dict["likhechw"] := [U("09B209BF099609C7099B09CB")]
Dict["likhechy"] := [U("09B209BF099609C7099B09BF")]
Dict["likheci"] := [U("09B209BF099609C7099B09BF")]
Dict["likheco"] := [U("09B209BF099609C7099B09CB")]
Dict["likhi"] := [U("09B209BF099609BF")]
Dict["likhia"] := [U("09B209BF099609C7")]
Dict["likho"] := [U("09B209BF099609CB")]
Dict["likhte"] := [U("09B209BF099609A409C7")]
Dict["likhun"] := [U("09B209BF099609C109A8")]
Dict["likhw"] := [U("09B209BF099609CB")]
Dict["likhy"] := [U("09B209BF099609BF")]
Dict["liki"] := [U("09B209BF099609BF")]
Dict["liko"] := [U("09B209BF099609CB")]
Dict["likte"] := [U("09B209BF099609A409C7")]
Dict["link"] := [U("09B209BF09820995")]
Dict["lipht"] := [U("09B209BF09AB099F")]
Dict["live"] := [U("09B209BE098709AD")]
Dict["loadsedding"] := [U("09B209CB09A109B609C709A109BF0982")]
Dict["loadshedding"] := [U("09B209CB09A109B609C709A109BF0982")]
Dict["loadsheding"] := [U("09B209CB09A109B609C709A109BF0982")]
Dict["loan"] := [U("09B209CB09A8")]
Dict["lobon"] := [U("09B209AC09A3")]
Dict["login"] := [U("09B20997098709A8")]
Dict["logout"] := [U("09B2099709860989099F")]
Dict["lok"] := [U("09B209CB0995")]
Dict["los"] := [U("09B209B8")]
Dict["loshs"] := [U("09B209B8")]
Dict["loss"] := [U("09B209B8")]
Dict["lyaptop"] := [U("09B209CD09AF09BE09AA099F09AA")]
Dict["ma"] := [U("09AE09BE")]
Dict["mac"] := [U("09AE09BE099B")]
Dict["mach"] := [U("09AE09BE099B")]
Dict["madam"] := [U("09AE09CD09AF09BE09A109BE09AE")]
Dict["maf"] := [U("09AE09BE09AB")]
Dict["mail"] := [U("09AE09C7098709B2")]
Dict["majhe"] := [U("09AE09BE099D09C7")]
Dict["majhemajhe"] := [U("09AE09BE099D09C709AE09BE099D09C7")]
Dict["mama"] := [U("09AE09BE09AE09BE")]
Dict["mangsho"] := [U("09AE09BE098209B8")]
Dict["mangshw"] := [U("09AE09BE098209B8")]
Dict["mangso"] := [U("09AE09BE098209B8")]
Dict["manus"] := [U("09AE09BE09A809C109B7")]
Dict["manush"] := [U("09AE09BE09A809C109B7")]
Dict["maph"] := [U("09AE09BE09AB")]
Dict["market"] := [U("09AE09BE09B009CD099509C7099F")]
Dict["marketing"] := [U("09AE09BE09B009CD099509C7099F09BF0982")]
Dict["mas"] := [U("09AE09BE09B8")]
Dict["masallah"] := [U("09AE09BE09B609BE098609B209CD09B209BE09B9")]
Dict["mash"] := [U("09AE09BE09B8")]
Dict["mashalah"] := [U("09AE09BE09B609BE098609B209CD09B209BE09B9")]
Dict["mashallah"] := [U("09AE09BE09B609BE098609B209CD09B209BE09B9")]
Dict["mashjid"] := [U("09AE09B8099C09BF09A6")]
Dict["masjid"] := [U("09AE09B8099C09BF09A6")]
Dict["maszid"] := [U("09AE09B8099C09BF09A6")]
Dict["mata"] := [U("09AE09BE09A509BE"), U("09AE09BE09A009C7")]
Dict["matha"] := [U("09AE09BE09A509BE")]
Dict["mati"] := [U("09AE09BE099F09BF")]
Dict["maty"] := [U("09AE09BE099F09BF")]
Dict["mazhe"] := [U("09AE09BE099D09C7")]
Dict["mazhemazhe"] := [U("09AE09BE099D09C709AE09BE099D09C7")]
Dict["mb"] := [U("098F09AE09AC09BF")]
Dict["megh"] := [U("09AE09C70998")]
Dict["meia"] := [U("09AE09C709AF09BC09C7")]
Dict["member"] := [U("09AE09C709AE09CD09AC09BE09B0")]
Dict["memori"] := [U("09AE09C709AE09CB09B009BF")]
Dict["memory"] := [U("09AE09C709AE09CB09B009BF")]
Dict["mesage"] := [U("09AE09C709B809C7099C")]
Dict["mesenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["meshsage"] := [U("09AE09C709B809C7099C")]
Dict["meshsenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["message"] := [U("09AE09C709B809C7099C")]
Dict["messenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["meya"] := [U("09AE09C709AF09BC09C7")]
Dict["meye"] := [U("09AE09C709AF09BC09C7")]
Dict["mic"] := [U("09AE09BE09870995")]
Dict["micro"] := [U("09AE09BE0987099509CD09B009CB")]
Dict["micrw"] := [U("09AE09BE0987099509CD09B009CB")]
Dict["mishti"] := [U("09AE09BF09B709CD099F09BF")]
Dict["mishty"] := [U("09AE09BF09B709CD099F09BF")]
Dict["misti"] := [U("09AE09BF09B709CD099F09BF")]
Dict["mobile"] := [U("09AE09CB09AC09BE098709B2")]
Dict["model"] := [U("09AE09A109C709B2")]
Dict["moila"] := [U("09AE09AF09BC09B209BE")]
Dict["moja"] := [U("09AE099C09BE")]
Dict["mojar"] := [U("09AE099C09BE09B0")]
Dict["mon"] := [U("09AE09A8")]
Dict["mondai"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["monday"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["mone"] := [U("09AE09A809C7")]
Dict["mongolbar"] := [U("09AE099909CD099709B209AC09BE09B0")]
Dict["montri"] := [U("09AE09A809CD09A409CD09B009C0")]
Dict["montry"] := [U("09AE09A809CD09A409CD09B009C0")]
Dict["moric"] := [U("09AE09B009BF099A")]
Dict["morich"] := [U("09AE09B009BF099A")]
Dict["morning"] := [U("09AE09B009CD09A809BF0982")]
Dict["motor"] := [U("09AE09CB099F09B0")]
Dict["motorcycle"] := [U("09AE09CB099F09B009B809BE0987099509C709B2")]
Dict["moyda"] := [U("09AE09AF09BC09A609BE")]
Dict["moza"] := [U("09AE099C09BE")]
Dict["mozar"] := [U("09AE099C09BE09B0")]
Dict["msg"] := [U("09AE09C709B809C7099C")]
Dict["mshg"] := [U("09AE09C709B809C7099C")]
Dict["mubarak"] := [U("09AE09CB09AC09BE09B00995")]
Dict["muk"] := [U("09AE09C10996")]
Dict["mukh"] := [U("09AE09C10996")]
Dict["murgi"] := [U("09AE09C109B0099709BF")]
Dict["murgy"] := [U("09AE09C109B0099709BF")]
Dict["na"] := [U("09A809BE")]
Dict["naa"] := [U("09A809BE")]
Dict["naak"] := [U("09A809BE0995")]
Dict["naam"] := [U("09A809BE09AE")]
Dict["nac"] := [U("09A809BE099A")]
Dict["nach"] := [U("09A809BE099A")]
Dict["nachi"] := [U("09A809BE099A09BF")]
Dict["nachte"] := [U("09A809BE099A09A409C7")]
Dict["nachy"] := [U("09A809BE099A09BF")]
Dict["naci"] := [U("09A809BE099A09BF")]
Dict["nacte"] := [U("09A809BE099A09A409C7")]
Dict["nagad"] := [U("09A8099709A6")]
Dict["nahole"] := [U("09A809BE09B909B209C7")]
Dict["nai"] := [U("09A809BE0987")]
Dict["namaj"] := [U("09A809BE09AE09BE099C")]
Dict["namaz"] := [U("09A809BE09AE09BE099C")]
Dict["name"] := [U("09A809BE09AE")]
Dict["nana"] := [U("09A809BE09A809BE")]
Dict["nani"] := [U("09A809BE09A809BF")]
Dict["nany"] := [U("09A809BE09A809BF")]
Dict["nao"] := [U("09A809BE0993")]
Dict["natok"] := [U("09A809BE099F0995")]
Dict["naw"] := [U("09A809BE0993")]
Dict["nay"] := [U("09A809BE0987")]
Dict["nei"] := [U("09A809C70987"), U("09A809BF0987")]
Dict["net"] := [U("09A809C7099F")]
Dict["neta"] := [U("09A809C709A409BE")]
Dict["ney"] := [U("09A809C709AF09BC")]
Dict["nia"] := [U("09A809BF09AF09BC09C7")]
Dict["nibe"] := [U("09A809BF09AC09C7")]
Dict["nibo"] := [U("09A809BF09AC09CB")]
Dict["nibw"] := [U("09A809BF09AC09CB")]
Dict["nice"] := [U("09A809BF099A09C7")]
Dict["niche"] := [U("09A809BF099A09C7")]
Dict["nid"] := [U("098F09A80986098709A109BF")]
Dict["night"] := [U("09A809BE0987099F")]
Dict["niia"] := [U("09A809BF09AF09BC09C7")]
Dict["nije"] := [U("09A809BF099C09C7")]
Dict["nijeke"] := [U("09A809BF099C09C7099509C7")]
Dict["nijer"] := [U("09A809BF099C09C709B0")]
Dict["nil"] := [U("09A809C009B2")]
Dict["niom"] := [U("09A809BF09AF09BC09AE")]
Dict["nirbachon"] := [U("09A809BF09B009CD09AC09BE099A09A8")]
Dict["nirbacon"] := [U("09A809BF09B009CD09AC09BE099A09A8")]
Dict["nischoi"] := [U("09A809BF09B609CD099A09AF09BC0987")]
Dict["nischoy"] := [U("09A809BF09B609CD099A09AF09BC0987")]
Dict["niscoi"] := [U("09A809BF09B609CD099A09AF09BC0987")]
Dict["nishchoi"] := [U("09A809BF09B609CD099A09AF09BC0987")]
Dict["nite"] := [U("09A809BF09A409C7")]
Dict["niya"] := [U("09A809BF09AF09BC09C7")]
Dict["niye"] := [U("09A809BF09AF09BC09C7")]
Dict["niyom"] := [U("09A809BF09AF09BC09AE")]
Dict["nize"] := [U("09A809BF099C09C7")]
Dict["nizeke"] := [U("09A809BF099C09C7099509C7")]
Dict["nizer"] := [U("09A809BF099C09C709B0")]
Dict["nobboi"] := [U("09A809AC09CD09AC0987")]
Dict["nobboy"] := [U("09A809AC09CD09AC0987")]
Dict["noboi"] := [U("09A809AC09CD09AC0987")]
Dict["nodi"] := [U("09A809A609C0")]
Dict["nody"] := [U("09A809A609C0")]
Dict["noi"] := [U("09A809AF09BC")]
Dict["nongra"] := [U("09A809CB098209B009BE")]
Dict["norom"] := [U("09A809B009AE")]
Dict["notun"] := [U("09A809A409C109A8")]
Dict["nouka"] := [U("09A809CC099509BE")]
Dict["noy"] := [U("09A809AF09BC")]
Dict["num"] := [U("09A809BE09AE09CD09AC09BE09B0")]
Dict["number"] := [U("09A809BE09AE09CD09AC09BE09B0")]
Dict["nurse"] := [U("09A809BE09B009CD09B8")]
Dict["nurshe"] := [U("09A809BE09B009CD09B8")]
Dict["o"] := [U("0993")]
Dict["obak"] := [U("098509AC09BE0995")]
Dict["obhabe"] := [U("099309AD09BE09AC09C7")]
Dict["obhen"] := [U("099309AD09C709A8")]
Dict["obhinondon"] := [U("098509AD09BF09A809A809CD09A609A8")]
Dict["odike"] := [U("099309A609BF099509C7")]
Dict["of"] := [U("098509AB")]
Dict["ofer"] := [U("098509AB09BE09B0")]
Dict["off"] := [U("098509AB")]
Dict["offer"] := [U("098509AB09BE09B0")]
Dict["office"] := [U("098509AB09BF09B8")]
Dict["offline"] := [U("098509AB09B209BE098709A8")]
Dict["ofice"] := [U("098509AB09BF09B8")]
Dict["ofline"] := [U("098509AB09B209BE098709A8")]
Dict["ogula"] := [U("0993099709C109B209BE")]
Dict["ogulo"] := [U("0993099709C109B209CB")]
Dict["oi"] := [U("09930987")]
Dict["oibhabe"] := [U("0993098709AD09BE09AC09C7")]
Dict["oidik"] := [U("0993098709A609BF0995")]
Dict["oijonno"] := [U("09930987099C09A809CD09AF")]
Dict["oikhan"] := [U("09930987099609BE09A8")]
Dict["oikhane"] := [U("09930987099609BE09A809C7")]
Dict["oipash"] := [U("0993098709AA09BE09B6")]
Dict["oisob"] := [U("0993098709B809AC")]
Dict["oita"] := [U("09930987099F09BE")]
Dict["oituku"] := [U("09930987099F09C1099509C1")]
Dict["ok"] := [U("0993099509C7")]
Dict["okai"] := [U("0993099509C7")]
Dict["okane"] := [U("0993099609BE09A809C7")]
Dict["okay"] := [U("0993099509C7")]
Dict["okhane"] := [U("0993099609BE09A809C7")]
Dict["omon"] := [U("099309AE09A8")]
Dict["on"] := [U("098509A8")]
Dict["onek"] := [U("098509A809C70995")]
Dict["oner"] := [U("098509A809CD09AF09C709B0")]
Dict["online"] := [U("098509A809B209BE098709A8")]
Dict["onner"] := [U("098509A809CD09AF09C709B0")]
Dict["onno"] := [U("098509A809CD09AF")]
Dict["onnoke"] := [U("098509A809CD09AF099509C7")]
Dict["onnw"] := [U("098509A809CD09AF")]
Dict["ono"] := [U("098509A809CD09AF")]
Dict["onoke"] := [U("098509A809CD09AF099509C7")]
Dict["opashe"] := [U("099309AA09BE09B609C7")]
Dict["open"] := [U("099309AA09C709A8")]
Dict["ophph"] := [U("098509AB")]
Dict["ophpher"] := [U("098509AB09BE09B0")]
Dict["ophphice"] := [U("098509AB09BF09B8")]
Dict["ophphline"] := [U("098509AB09B209BE098709A8")]
Dict["option"] := [U("098509AA09B609A8")]
Dict["order"] := [U("098509B009CD09A109BE09B0")]
Dict["original"] := [U("098509B009BF099C09BF09A809BE09B2")]
Dict["osadharon"] := [U("098509B809BE09A709BE09B009A3")]
Dict["osanto"] := [U("098509B609BE09A809CD09A4")]
Dict["oshadaron"] := [U("098509B809BE09A709BE09B009A3")]
Dict["oshadharon"] := [U("098509B809BE09A709BE09B009A3")]
Dict["oshanto"] := [U("098509B609BE09A809CD09A4")]
Dict["oshantw"] := [U("098509B609BE09A809CD09A4")]
Dict["oshud"] := [U("099309B709C109A7")]
Dict["oshudh"] := [U("099309B709C109A7")]
Dict["oshushtho"] := [U("098509B809C109B809CD09A5")]
Dict["oshustho"] := [U("098509B809C109B809CD09A5")]
Dict["oshusthw"] := [U("098509B809C109B809CD09A5")]
Dict["oshusto"] := [U("098509B809C109B809CD09A5")]
Dict["osob"] := [U("099309B809AC")]
Dict["osudh"] := [U("099309B709C109A7")]
Dict["osustho"] := [U("098509B809C109B809CD09A5")]
Dict["ota"] := [U("0993099F09BE")]
Dict["otai"] := [U("0993099F09BE0987")]
Dict["otobar"] := [U("098509A409AC09BE09B0")]
Dict["otodin"] := [U("098509A409A609BF09A8")]
Dict["otokhon"] := [U("098509A4099509CD09B709A3")]
Dict["otokichu"] := [U("098509A4099509BF099B09C1")]
Dict["otota"] := [U("098509A4099F09BE")]
Dict["ototuku"] := [U("098509A4099F09C1099509C1")]
Dict["oven"] := [U("099309AD09C709A8")]
Dict["ovinondon"] := [U("098509AD09BF09A809A809CD09A609A8")]
Dict["paa"] := [U("09AA09BE")]
Dict["packet"] := [U("09AA09CD09AF09BE099509C7099F")]
Dict["page"] := [U("09AA09C7099C")]
Dict["pagol"] := [U("09AA09BE099709B2")]
Dict["pahar"] := [U("09AA09BE09B909BE09A109BC")]
Dict["panc"] := [U("09AA09BE0981099A")]
Dict["panch"] := [U("09AA09BE0981099A")]
Dict["pani"] := [U("09AA09BE09A809BF")]
Dict["pany"] := [U("09AA09BE09A809BF")]
Dict["paper"] := [U("09AA09C709AA09BE09B0")]
Dict["parben"] := [U("09AA09BE09B009AC09C709A8")]
Dict["parbena"] := [U("09AA09BE09B009AC09C709A809BE")]
Dict["parbo"] := [U("09AA09BE09B009AC09CB")]
Dict["parbw"] := [U("09AA09BE09B009AC09CB")]
Dict["pare"] := [U("09AA09BE09B009C7")]
Dict["paren"] := [U("09AA09BE09B009C709A8")]
Dict["pari"] := [U("09AA09BE09B009BF")]
Dict["parina"] := [U("09AA09BE09B009BF09A809BE")]
Dict["paro"] := [U("09AA09BE09B009CB")]
Dict["parte"] := [U("09AA09BE09B009A409C7")]
Dict["parw"] := [U("09AA09BE09B009CB")]
Dict["pary"] := [U("09AA09BE09B009BF")]
Dict["pas"] := [U("09AA09BE09B8"), U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["pashs"] := [U("09AA09BE09B8"), U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["pashsport"] := [U("09AA09BE09B809AA09CB09B009CD099F")]
Dict["pashsword"] := [U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["pashte"] := [U("09AA09C709B809CD099F")]
Dict["pasport"] := [U("09AA09BE09B809AA09CB09B009CD099F")]
Dict["pass"] := [U("09AA09BE09B8"), U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["passport"] := [U("09AA09BE09B809AA09CB09B009CD099F")]
Dict["password"] := [U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["paste"] := [U("09AA09C709B809CD099F")]
Dict["pasword"] := [U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")]
Dict["pata"] := [U("09AA09BE09A409BE")]
Dict["patabo"] := [U("09AA09BE09A009BE09AC09CB")]
Dict["patai"] := [U("09AA09BE09A009BE0987")]
Dict["patao"] := [U("09AA09BE09A009BE0993")]
Dict["patate"] := [U("09AA09BE09A009BE09A409C7")]
Dict["pathabo"] := [U("09AA09BE09A009BE09AC09CB")]
Dict["pathabw"] := [U("09AA09BE09A009BE09AC09CB")]
Dict["pathai"] := [U("09AA09BE09A009BE0987")]
Dict["pathao"] := [U("09AA09BE09A009BE0993")]
Dict["pathate"] := [U("09AA09BE09A009BE09A409C7")]
Dict["pathaw"] := [U("09AA09BE09A009BE0993")]
Dict["pathay"] := [U("09AA09BE09A009BE0987")]
Dict["payment"] := [U("09AA09C709AE09C709A809CD099F")]
Dict["pbo"] := [U("09AA09BE09AC09CB")]
Dict["pbw"] := [U("09AA09BE09AC09CB")]
Dict["pc"] := [U("09AA09BF09B809BF")]
Dict["pdf"] := [U("09AA09BF09A109BF098F09AB")]
Dict["pdph"] := [U("09AA09BF09A109BF098F09AB")]
Dict["permit"] := [U("09AA09BE09B009AE09BF099F")]
Dict["peyaj"] := [U("09AA09C7098109AF09BC09BE099C")]
Dict["peyara"] := [U("09AA09C709AF09BC09BE09B009BE")]
Dict["peyaz"] := [U("09AA09C7098109AF09BC09BE099C")]
Dict["ph"] := [U("09AB09CB09A8")]
Dict["phacebook"] := [U("09AB09C709B809AC09C10995")]
Dict["phactory"] := [U("09AB09CD09AF09BE099509CD099F09B009BF")]
Dict["phake"] := [U("09AB09C70995")]
Dict["phaltu"] := [U("09AB09BE09B209A409C1")]
Dict["phan"] := [U("09AB09CD09AF09BE09A8")]
Dict["pharmaci"] := [U("09AB09BE09B009CD09AE09C709B809BF")]
Dict["pharmacy"] := [U("09AB09BE09B009CD09AE09C709B809BF")]
Dict["phast"] := [U("09AB09BE09B809CD099F")]
Dict["phb"] := [U("09AB09C709B809AC09C10995")]
Dict["pherry"] := [U("09AB09C709B009BF")]
Dict["phile"] := [U("09AB09BE098709B2")]
Dict["phirbo"] := [U("09AB09BF09B009AC09CB")]
Dict["phire"] := [U("09AB09BF09B009C7")]
Dict["phirte"] := [U("09AB09BF09B009A409C7")]
Dict["phix"] := [U("09AB09BF099509CD09B8")]
Dict["phlight"] := [U("09AB09CD09B209BE0987099F")]
Dict["phn"] := [U("09AB09CB09A8")]
Dict["phol"] := [U("09AB09B2")]
Dict["pholder"] := [U("09AB09CB09B209CD09A109BE09B0")]
Dict["phollow"] := [U("09AB09B209CB")]
Dict["phollower"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["phone"] := [U("09AB09CB09A8")]
Dict["phootball"] := [U("09AB09C1099F09AC09B2")]
Dict["photo"] := [U("099B09AC09BF")]
Dict["photocopi"] := [U("09AB099F09CB099509AA09BF")]
Dict["photocopy"] := [U("09AB099F09CB099509AA09BF")]
Dict["photw"] := [U("099B09AC09BF")]
Dict["phree"] := [U("09AB09CD09B009BF")]
Dict["phriday"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["phridge"] := [U("09AB09CD09B009BF099C")]
Dict["phrnd"] := [U("09AC09A809CD09A709C1")]
Dict["phul"] := [U("09AB09C109B2")]
Dict["phuphu"] := [U("09AB09C109AB09C1")]
Dict["pic"] := [U("099B09AC09BF")]
Dict["pickup"] := [U("09AA09BF0995098609AA")]
Dict["picture"] := [U("099B09AC09BF")]
Dict["pipe"] := [U("09AA09BE098709AA")]
Dict["pita"] := [U("09AA09BF09A009BE")]
Dict["pitha"] := [U("09AA09BF09A009BE")]
Dict["plai"] := [U("09AA09CD09B209C7")]
Dict["plane"] := [U("09AA09CD09B209C709A8")]
Dict["plate"] := [U("09AA09CD09B209C7099F")]
Dict["play"] := [U("09AA09CD09B209C7")]
Dict["please"] := [U("09AA09CD09B209BF099C")]
Dict["pleashe"] := [U("09AA09CD09B209BF099C")]
Dict["plj"] := [U("09AA09CD09B209BF099C")]
Dict["pls"] := [U("09AA09CD09B209BF099C")]
Dict["plsh"] := [U("09AA09CD09B209BF099C")]
Dict["plz"] := [U("09AA09CD09B209BF099C")]
Dict["polao"] := [U("09AA09CB09B209BE0993")]
Dict["polaw"] := [U("09AA09CB09B209BE0993")]
Dict["police"] := [U("09AA09C109B209BF09B6")]
Dict["poncas"] := [U("09AA099E09CD099A09BE09B6")]
Dict["poncash"] := [U("09AA099E09CD099A09BE09B6")]
Dict["ponchas"] := [U("09AA099E09CD099A09BE09B6")]
Dict["ponchash"] := [U("09AA099E09CD099A09BE09B6")]
Dict["ponero"] := [U("09AA09A809C709B009CB")]
Dict["ponerw"] := [U("09AA09A809C709B009CB")]
Dict["porajoi"] := [U("09AA09B009BE099C09AF09BC")]
Dict["porajoy"] := [U("09AA09B009BE099C09AF09BC")]
Dict["porano"] := [U("09AA09A109BC09BE09A809CB")]
Dict["poranw"] := [U("09AA09A109BC09BE09A809CB")]
Dict["porazoy"] := [U("09AA09B009BE099C09AF09BC")]
Dict["porben"] := [U("09AA09A109BC09AC09C709A8")]
Dict["porbo"] := [U("09AA09A109BC09AC09CB")]
Dict["porbw"] := [U("09AA09A109BC09AC09CB")]
Dict["porce"] := [U("09AA09A109BC099B09C7")]
Dict["porche"] := [U("09AA09A109BC099B09C7")]
Dict["porchhi"] := [U("09AA09A109BC099B09BF")]
Dict["porchhy"] := [U("09AA09A109BC099B09BF")]
Dict["porchi"] := [U("09AA09A109BC099B09BF")]
Dict["pore"] := [U("09AA09A109BC09C7"), U("09AA09B009C7")]
Dict["poreche"] := [U("09AA09A109BC09C7099B09C7")]
Dict["porechhe"] := [U("09AA09A109BC09C7099B09C7")]
Dict["porechi"] := [U("09AA09A109BC09C7099B09BF")]
Dict["porecho"] := [U("09AA09A109BC09C7099B09CB")]
Dict["porechw"] := [U("09AA09A109BC09C7099B09CB")]
Dict["porechy"] := [U("09AA09A109BC09C7099B09BF")]
Dict["poreci"] := [U("09AA09A109BC09C7099B09BF")]
Dict["poreco"] := [U("09AA09A109BC09C7099B09CB")]
Dict["porei"] := [U("09AA09B009C70987")]
Dict["pori"] := [U("09AA09A109BC09BF")]
Dict["poria"] := [U("09AA09A109BC09C7")]
Dict["poribar"] := [U("09AA09B009BF09AC09BE09B0")]
Dict["porishkar"] := [U("09AA09B009BF09B709CD099509BE09B0")]
Dict["poriskar"] := [U("09AA09B009BF09B709CD099509BE09B0")]
Dict["poro"] := [U("09AA09A109BC09CB")]
Dict["porte"] := [U("09AA09A109BC09A409C7")]
Dict["porun"] := [U("09AA09A109BC09C109A8")]
Dict["porw"] := [U("09AA09A109BC09CB")]
Dict["pory"] := [U("09AA09A109BC09BF")]
Dict["posht"] := [U("09AA09CB09B809CD099F")]
Dict["post"] := [U("09AA09CB09B809CD099F")]
Dict["pran"] := [U("09AA09CD09B009BE09A3")]
Dict["prbo"] := [U("09AA09BE09B009AC09CB")]
Dict["prbw"] := [U("09AA09BE09B009AC09CB")]
Dict["price"] := [U("09AA09CD09B009BE098709B8")]
Dict["print"] := [U("09AA09CD09B009BF09A809CD099F")]
Dict["proceshsor"] := [U("09AA09CD09B009B809C709B809B0")]
Dict["procesor"] := [U("09AA09CD09B009B809C709B809B0")]
Dict["processor"] := [U("09AA09CD09B009B809C709B809B0")]
Dict["prodanmontri"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["prodhanmontri"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["prodhanmontry"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["product"] := [U("09AA09CD09B009CB09A109BE099509CD099F")]
Dict["profile"] := [U("09AA09CD09B009CB09AB09BE098709B2")]
Dict["profit"] := [U("09AA09CD09B009AB09BF099F")]
Dict["prophile"] := [U("09AA09CD09B009CB09AB09BE098709B2")]
Dict["prophit"] := [U("09AA09CD09B009AB09BF099F")]
Dict["protector"] := [U("09AA09CD09B009CB099F09C7099509CD099F09B0")]
Dict["protek"] := [U("09AA09CD09B009A409CD09AF09C70995")]
Dict["prothom"] := [U("09AA09CD09B009A509AE")]
Dict["prothome"] := [U("09AA09CD09B009A509AE09C7")]
Dict["proti"] := [U("09AA09CD09B009A409BF")]
Dict["protidin"] := [U("09AA09CD09B009A409BF09A609BF09A8")]
Dict["protom"] := [U("09AA09CD09B009A509AE")]
Dict["prottek"] := [U("09AA09CD09B009A409CD09AF09C70995")]
Dict["proty"] := [U("09AA09CD09B009A409BF")]
Dict["prte"] := [U("09AA09BE09B009A409C7")]
Dict["pump"] := [U("09AA09BE09AE09CD09AA")]
Dict["purano"] := [U("09AA09C109B009BE09A809CB")]
Dict["puranw"] := [U("09AA09C109B009BE09A809CB")]
Dict["puri"] := [U("09AA09C109B009BF")]
Dict["puro"] := [U("09AA09C109B009CB")]
Dict["purw"] := [U("09AA09C109B009CB")]
Dict["pury"] := [U("09AA09C109B009BF")]
Dict["qualiti"] := [U("099509CB09AF09BC09BE09B209BF099F09BF")]
Dict["quality"] := [U("099509CB09AF09BC09BE09B209BF099F09BF")]
Dict["quran"] := [U("099509C109B0098609A8")]
Dict["r"] := [U("098609B0")]
Dict["raat"] := [U("09B009BE09A4")]
Dict["rag"] := [U("09B009BE0997")]
Dict["rake"] := [U("09B009BE099609C7")]
Dict["rakhe"] := [U("09B009BE099609C7")]
Dict["rakhi"] := [U("09B009BE099609BF")]
Dict["rakho"] := [U("09B009BE099609CB")]
Dict["rakhw"] := [U("09B009BE099609CB")]
Dict["rakhy"] := [U("09B009BE099609BF")]
Dict["raki"] := [U("09B009BE099609BF")]
Dict["rako"] := [U("09B009BE099609CB")]
Dict["ram"] := [U("09B0200D09CD09AF09BE09AE")]
Dict["ramadan"] := [U("09B009AE099C09BE09A8")]
Dict["ranaghor"] := [U("09B009BE09A809CD09A809BE099809B0")]
Dict["rannaghor"] := [U("09B009BE09A809CD09A809BE099809B0")]
Dict["rashta"] := [U("09B009BE09B809CD09A409BE")]
Dict["rashtro"] := [U("09B009BE09B709CD099F09CD09B0")]
Dict["rashtropoti"] := [U("09B009BE09B709CD099F09CD09B009AA09A409BF")]
Dict["rashtropoty"] := [U("09B009BE09B709CD099F09CD09B009AA09A409BF")]
Dict["rashtrw"] := [U("09B009BE09B709CD099F09CD09B0")]
Dict["rasta"] := [U("09B009BE09B809CD09A409BE")]
Dict["rastro"] := [U("09B009BE09B709CD099F09CD09B0")]
Dict["rastropoti"] := [U("09B009BE09B709CD099F09CD09B009AA09A409BF")]
Dict["reac"] := [U("09B009BF099A")]
Dict["reach"] := [U("09B009BF099A")]
Dict["readi"] := [U("09B009C709A109BF")]
Dict["ready"] := [U("09B009C709A109BF")]
Dict["receipt"] := [U("09B009B809BF09A6")]
Dict["refund"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["rephund"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["repli"] := [U("09B009BF09AA09CD09B209BE0987")]
Dict["reply"] := [U("09B009BF09AA09CD09B209BE0987")]
Dict["report"] := [U("09B009BF09AA09CB09B009CD099F")]
Dict["reshtart"] := [U("09B009BF09B809CD099F09BE09B009CD099F")]
Dict["reshtaurant"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["restart"] := [U("09B009BF09B809CD099F09BE09B009CD099F")]
Dict["restaurant"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["retail"] := [U("09B009BF099F09C7098709B2")]
Dict["return"] := [U("09B009BF099F09BE09B009CD09A8")]
Dict["ricksaw"] := [U("09B009BF099509B609BE")]
Dict["rickshao"] := [U("09B009BF099509B609BE")]
Dict["rickshaw"] := [U("09B009BF099509B609BE")]
Dict["riksa"] := [U("09B009BF099509B609BE")]
Dict["riksha"] := [U("09B009BF099509B609BE")]
Dict["rin"] := [U("098B09A3")]
Dict["robibar"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["rod"] := [U("09B009CB09A6")]
Dict["rog"] := [U("09B009CB0997")]
Dict["roj"] := [U("09B009CB099C")]
Dict["roja"] := [U("09B009CB099C09BE")]
Dict["rokto"] := [U("09B0099509CD09A4")]
Dict["roktw"] := [U("09B0099509CD09A4")]
Dict["rom"] := [U("09B009AE")]
Dict["room"] := [U("09B009C109AE")]
Dict["roshid"] := [U("09B009B809BF09A6")]
Dict["roshogola"] := [U("09B009B8099709CB09B209CD09B209BE")]
Dict["roshogolla"] := [U("09B009B8099709CB09B209CD09B209BE")]
Dict["roshun"] := [U("09B009B809C109A8")]
Dict["rosid"] := [U("09B009B809BF09A6")]
Dict["rosogolla"] := [U("09B009B8099709CB09B209CD09B209BE")]
Dict["rosun"] := [U("09B009B809C109A8")]
Dict["roz"] := [U("09B009CB099C")]
Dict["roza"] := [U("09B009CB099C09BE")]
Dict["rum"] := [U("09B009C109AE")]
Dict["ruti"] := [U("09B009C1099F09BF")]
Dict["ruty"] := [U("09B009C1099F09BF")]
Dict["saat"] := [U("09B709BE099F")]
Dict["sada"] := [U("09B809BE09A609BE")]
Dict["sadhinota"] := [U("09B809CD09AC09BE09A709C009A809A409BE")]
Dict["sagor"] := [U("09B809BE099709B0")]
Dict["sagotom"] := [U("09B809CD09AC09BE099709A409AE")]
Dict["sahito"] := [U("09B809BE09B909BF09A409CD09AF")]
Dict["sahitto"] := [U("09B809BE09B909BF09A409CD09AF")]
Dict["sahittw"] := [U("09B809BE09B909BF09A409CD09AF")]
Dict["salari"] := [U("09B809CD09AF09BE09B209BE09B009BF")]
Dict["salary"] := [U("09B809CD09AF09BE09B209BE09B009BF")]
Dict["sami"] := [U("09B809CD09AC09BE09AE09C0")]
Dict["sandes"] := [U("09B809A809CD09A609C709B6")]
Dict["sandesh"] := [U("09B809A809CD09A609C709B6")]
Dict["santi"] := [U("09B609BE09A809CD09A409BF")]
Dict["santo"] := [U("09B609BE09A809CD09A4")]
Dict["sare"] := [U("09B609C709AF09BC09BE09B0")]
Dict["sastho"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["sasuri"] := [U("09B609BE09B609C109A109BC09BF")]
Dict["sat"] := [U("09B809BE09A4")]
Dict["sate"] := [U("09B809BE09A509C7")]
Dict["sathe"] := [U("09B809BE09A509C7")]
Dict["saturdai"] := [U("09B609A809BF09AC09BE09B0")]
Dict["saturday"] := [U("09B609A809BF09AC09BE09B0")]
Dict["scan"] := [U("09B809CD099509CD09AF09BE09A8")]
Dict["school"] := [U("09B809CD099509C109B2")]
Dict["schul"] := [U("09B809CD099509C109B2")]
Dict["scool"] := [U("09B809CD099509C109B2")]
Dict["screen"] := [U("09B809CD099509CD09B009BF09A8")]
Dict["screenshot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["screensot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["scrin"] := [U("09B809CD099509CD09B009BF09A8")]
Dict["scrinshot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["se"] := [U("09B809C7")]
Dict["searc"] := [U("09B809BE09B009CD099A")]
Dict["search"] := [U("09B809BE09B009CD099A")]
Dict["sebhab e"] := [U("09B809C709AD09BE09AC09C7")]
Dict["sedike"] := [U("09B809C709A609BF099509C7")]
Dict["segula"] := [U("09B809C7099709C109B209BE")]
Dict["segulo"] := [U("09B809C7099709C109B209CB")]
Dict["sei"] := [U("09B809C70987")]
Dict["seibhabe"] := [U("09B809C7098709AD09BE09AC09C7")]
Dict["seidik"] := [U("09B809C7098709A609BF0995")]
Dict["seijonno"] := [U("09B809C70987099C09A809CD09AF")]
Dict["seikhan"] := [U("09B809C70987099609BE09A8")]
Dict["seikhane"] := [U("09B809C70987099609BE09A809C7")]
Dict["seipash"] := [U("09B809C7098709AA09BE09B6")]
Dict["seisob"] := [U("09B809C7098709B809AC")]
Dict["seita"] := [U("09B809C70987099F09BE")]
Dict["sejonno"] := [U("09B809C7099C09A809CD09AF")]
Dict["seka"] := [U("09B609C7099609BE")]
Dict["sekane"] := [U("09B809C7099609BE09A809C7")]
Dict["sekha"] := [U("09B609C7099609BE")]
Dict["sekhane"] := [U("09B809C7099609BE09A809C7")]
Dict["sel"] := [U("09B809C709B2")]
Dict["sell"] := [U("09B809C709B2")]
Dict["send"] := [U("09B809C709A809CD09A1")]
Dict["sepashe"] := [U("09B809C709AA09BE09B609C7")]
Dict["ses"] := [U("09B609C709B7")]
Dict["sesob"] := [U("09B809C709B809AC")]
Dict["seta"] := [U("09B809C7099F09BE")]
Dict["setai"] := [U("09B809C7099F09BE0987")]
Dict["seting"] := [U("09B809C7099F09BF0982")]
Dict["setings"] := [U("09B809C7099F09BF098209B8")]
Dict["setting"] := [U("09B809C7099F09BF0982")]
Dict["settings"] := [U("09B809C7099F09BF098209B8")]
Dict["shaat"] := [U("09B709BE099F")]
Dict["shada"] := [U("09B809BE09A609BE")]
Dict["shadhinota"] := [U("09B809CD09AC09BE09A709C009A809A409BE")]
Dict["shadinota"] := [U("09B809CD09AC09BE09A709C009A809A409BE")]
Dict["shagor"] := [U("09B809BE099709B0")]
Dict["shagotom"] := [U("09B809CD09AC09BE099709A409AE")]
Dict["shahitto"] := [U("09B809BE09B909BF09A409CD09AF")]
Dict["shalary"] := [U("09B809CD09AF09BE09B209BE09B009BF")]
Dict["shami"] := [U("09B809CD09AC09BE09AE09C0")]
Dict["shamy"] := [U("09B809CD09AC09BE09AE09C0")]
Dict["shandesh"] := [U("09B809A809CD09A609C709B6")]
Dict["shanti"] := [U("09B609BE09A809CD09A409BF")]
Dict["shanto"] := [U("09B609BE09A809CD09A4")]
Dict["shantw"] := [U("09B609BE09A809CD09A4")]
Dict["shanty"] := [U("09B609BE09A809CD09A409BF")]
Dict["share"] := [U("09B609C709AF09BC09BE09B0")]
Dict["shashtho"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shashuri"] := [U("09B609BE09B609C109A109BC09BF")]
Dict["shashury"] := [U("09B609BE09B609C109A109BC09BF")]
Dict["shastho"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shasthw"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shasto"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shat"] := [U("09B809BE09A4")]
Dict["shathe"] := [U("09B809BE09A509C7")]
Dict["shathei"] := [U("09B809BE09A509C70987")]
Dict["shaturday"] := [U("09B609A809BF09AC09BE09B0")]
Dict["shcan"] := [U("09B809CD099509CD09AF09BE09A8")]
Dict["shchool"] := [U("09B809CD099509C109B2")]
Dict["shcreen"] := [U("09B809CD099509CD09B009BF09A8")]
Dict["shcreenshot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["she"] := [U("09B809C7")]
Dict["shearch"] := [U("09B809BE09B009CD099A")]
Dict["sheka"] := [U("09B609C7099609BE")]
Dict["shekha"] := [U("09B609C7099609BE")]
Dict["shekhane"] := [U("09B809C7099609BE09A809C7")]
Dict["shell"] := [U("09B809C709B2")]
Dict["shend"] := [U("09B809C709A809CD09A1")]
Dict["shesh"] := [U("09B609C709B7")]
Dict["sheshe"] := [U("09B609C709B709C7")]
Dict["shetting"] := [U("09B809C7099F09BF0982")]
Dict["shettingsh"] := [U("09B809C7099F09BF098209B8")]
Dict["shighroi"] := [U("09B609C0099809CD09B00987")]
Dict["shikbo"] := [U("09B609BF099609AC09CB")]
Dict["shike"] := [U("09B609BF099609C7")]
Dict["shikha"] := [U("09B609BF099509CD09B709BE")]
Dict["shikhbo"] := [U("09B609BF099609AC09CB")]
Dict["shikhbw"] := [U("09B609BF099609AC09CB")]
Dict["shikhe"] := [U("09B609BF099609C7")]
Dict["shikhi"] := [U("09B609BF099609BF")]
Dict["shikhte"] := [U("09B609BF099609A409C7")]
Dict["shikhy"] := [U("09B609BF099609BF")]
Dict["shiki"] := [U("09B609BF099609BF")]
Dict["shikka"] := [U("09B609BF099509CD09B709BE")]
Dict["shikkha"] := [U("09B609BF099509CD09B709BE")]
Dict["shikte"] := [U("09B609BF099609A409C7")]
Dict["shim"] := [U("09B809BF09AE")]
Dict["shingara"] := [U("09B809BF099909CD099709BE09B009BE")]
Dict["shir"] := [U("09B809CD09AF09BE09B0")]
Dict["shiri"] := [U("09B809BF098109A109BC09BF")]
Dict["shiry"] := [U("09B809BF098109A109BC09BF")]
Dict["shit"] := [U("09B609C009A4")]
Dict["shize"] := [U("09B809BE0987099C")]
Dict["shlow"] := [U("09B809CD09B209CB")]
Dict["shob"] := [U("09B809AC")]
Dict["shobai"] := [U("09B809AC09BE0987")]
Dict["shobar"] := [U("09B809AC09BE09B0")]
Dict["shobay"] := [U("09B809AC09BE0987")]
Dict["shobji"] := [U("09B809AC099C09BF")]
Dict["shobkichu"] := [U("09B809AC099509BF099B09C1")]
Dict["shobkicu"] := [U("09B809AC099509BF099B09C1")]
Dict["shobkishu"] := [U("09B809AC099509BF099B09C1")]
Dict["shobkisu"] := [U("09B809AC099509BF099B09C1")]
Dict["shobshomoi"] := [U("09B809AC09B809AE09AF09BC")]
Dict["shobshomoy"] := [U("09B809AC09B809AE09AF09BC")]
Dict["shobsomoi"] := [U("09B809AC09B809AE09AF09BC")]
Dict["shobsomoy"] := [U("09B809AC09B809AE09AF09BC")]
Dict["shobuj"] := [U("09B809AC09C1099C")]
Dict["shoftware"] := [U("09B809AB099F099309AF09BC09CD09AF09BE09B0")]
Dict["shohoj"] := [U("09B809B9099C")]
Dict["shohoje"] := [U("09B809B9099C09C7")]
Dict["shohor"] := [U("09B609B909B0")]
Dict["shohoz"] := [U("09B809B9099C")]
Dict["shohoze"] := [U("09B809B9099C09C7")]
Dict["shokal"] := [U("09B8099509BE09B2")]
Dict["shoktishali"] := [U("09B6099509CD09A409BF09B609BE09B209C0")]
Dict["shoktishaly"] := [U("09B6099509CD09A409BF09B609BE09B209C0")]
Dict["shokto"] := [U("09B6099509CD09A4")]
Dict["shoktw"] := [U("09B6099509CD09A4")]
Dict["sholo"] := [U("09B709CB09B209CB")]
Dict["sholw"] := [U("09B709CB09B209CB")]
Dict["shomadan"] := [U("09B809AE09BE09A709BE09A8")]
Dict["shomadhan"] := [U("09B809AE09BE09A709BE09A8")]
Dict["shomaj"] := [U("09B809AE09BE099C")]
Dict["shomaz"] := [U("09B809AE09BE099C")]
Dict["shombar"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["shomoi"] := [U("09B809AE09AF09BC")]
Dict["shomosa"] := [U("09B809AE09B809CD09AF09BE")]
Dict["shomoshsa"] := [U("09B809AE09B809CD09AF09BE")]
Dict["shomossa"] := [U("09B809AE09B809CD09AF09BE")]
Dict["shomoy"] := [U("09B809AE09AF09BC")]
Dict["shomucha"] := [U("09B809AE09C1099A09BE")]
Dict["shonano"] := [U("09B609CB09A809BE09A809CB")]
Dict["shonanw"] := [U("09B609CB09A809BE09A809CB")]
Dict["shondha"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["shonibar"] := [U("09B609A809BF09AC09BE09B0")]
Dict["shontan"] := [U("09B809A809CD09A409BE09A8")]
Dict["shop"] := [U("09B609AA")]
Dict["shopno"] := [U("09B809CD09AC09AA09CD09A8")]
Dict["shopnw"] := [U("09B809CD09AC09AA09CD09A8")]
Dict["shoptaho"] := [U("09B809AA09CD09A409BE09B9")]
Dict["shorir"] := [U("09B609B009C009B0")]
Dict["shorkar"] := [U("09B809B0099509BE09B0")]
Dict["shorot"] := [U("09B609B009CE")]
Dict["shorry"] := [U("09B809B009BF")]
Dict["shoshta"] := [U("09B809B809CD09A409BE")]
Dict["shoshtha"] := [U("09B809B809CD09A409BE")]
Dict["shoshur"] := [U("09B609CD09AC09B609C109B0")]
Dict["shotero"] := [U("09B809A409C709B009CB")]
Dict["shothik"] := [U("09B809A009BF0995")]
Dict["shotor"] := [U("09B809A409CD09A409B0")]
Dict["shottor"] := [U("09B809A409CD09A409B0")]
Dict["showroom"] := [U("09B609CB09B009C109AE")]
Dict["showrum"] := [U("09B609CB09B009C109AE")]
Dict["shpam"] := [U("09B809CD09AA09CD09AF09BE09AE")]
Dict["shpeaker"] := [U("09B809CD09AA09BF099509BE09B0")]
Dict["shpeed"] := [U("09B809CD09AA09BF09A1")]
Dict["shpoon"] := [U("099A09BE09AE099A")]
Dict["shry"] := [U("09B809B009BF")]
Dict["shtart"] := [U("09B809CD099F09BE09B009CD099F")]
Dict["shtation"] := [U("09B809CD099F09C709B609A8")]
Dict["shtock"] := [U("09B809CD099F0995")]
Dict["shtop"] := [U("09B809CD099F09AA")]
Dict["shtorage"] := [U("09B809CD099F09CB09B009C7099C")]
Dict["shtore"] := [U("09B809CD099F09CB09B0")]
Dict["shtri"] := [U("09B809CD09A409CD09B009C0")]
Dict["shtudent"] := [U("099B09BE09A409CD09B0")]
Dict["shubhanallah"] := [U("09B809C109AC09B909BE09A809BE09B209CD09B209BE09B9")]
Dict["shubhecha"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["shubhechha"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["shubho"] := [U("09B609C109AD")]
Dict["shubhw"] := [U("09B609C109AD")]
Dict["shudh"] := [U("09B809C109A6")]
Dict["shukh"] := [U("09B809C10996")]
Dict["shukhi"] := [U("09B809C1099609C0")]
Dict["shukno"] := [U("09B609C1099509A809CB")]
Dict["shuknw"] := [U("09B609C1099509A809CB")]
Dict["shukrobar"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["shunben"] := [U("09B609C109A809AC09C709A8")]
Dict["shunbo"] := [U("09B609C109A809AC09CB")]
Dict["shunbw"] := [U("09B609C109A809AC09CB")]
Dict["shunce"] := [U("09B609C109A8099B09C7")]
Dict["shunche"] := [U("09B609C109A8099B09C7")]
Dict["shunchi"] := [U("09B609C109A8099B09BF")]
Dict["shunchy"] := [U("09B609C109A8099B09BF")]
Dict["shunci"] := [U("09B609C109A8099B09BF")]
Dict["shunday"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["shundor"] := [U("09B809C109A809CD09A609B0")]
Dict["shune"] := [U("09B609C109A809C7")]
Dict["shuneche"] := [U("09B609C109A809C7099B09C7")]
Dict["shunechhe"] := [U("09B609C109A809C7099B09C7")]
Dict["shunechi"] := [U("09B609C109A809C7099B09BF")]
Dict["shunecho"] := [U("09B609C109A809C7099B09CB")]
Dict["shunechw"] := [U("09B609C109A809C7099B09CB")]
Dict["shunechy"] := [U("09B609C109A809C7099B09BF")]
Dict["shuneci"] := [U("09B609C109A809C7099B09BF")]
Dict["shuneco"] := [U("09B609C109A809C7099B09CB")]
Dict["shuni"] := [U("09B609C109A809BF")]
Dict["shunia"] := [U("09B609C109A809C7")]
Dict["shuno"] := [U("09B609C109A809CB")]
Dict["shunun"] := [U("09B609C109A809C109A8")]
Dict["shunw"] := [U("09B609C109A809CB")]
Dict["shuny"] := [U("09B609C109A809BF")]
Dict["shupplier"] := [U("09B809BE09AA09CD09B209BE09AF09BC09BE09B0")]
Dict["shurjo"] := [U("09B809C209B009CD09AF")]
Dict["shuru"] := [U("09B609C109B009C1")]
Dict["shushtho"] := [U("09B809C109B809CD09A5")]
Dict["shuvechha"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["shuvo"] := [U("09B609C109AD")]
Dict["sije"] := [U("09B809BE0987099C")]
Dict["sikbo"] := [U("09B609BF099609AC09CB")]
Dict["sike"] := [U("09B609BF099609C7")]
Dict["sikhbo"] := [U("09B609BF099609AC09CB")]
Dict["sikhe"] := [U("09B609BF099609C7")]
Dict["sikhi"] := [U("09B609BF099609BF")]
Dict["sikhte"] := [U("09B609BF099609A409C7")]
Dict["siki"] := [U("09B609BF099609BF")]
Dict["sikka"] := [U("09B609BF099509CD09B709BE")]
Dict["sikkha"] := [U("09B609BF099509CD09B709BE")]
Dict["sikte"] := [U("09B609BF099609A409C7")]
Dict["sim"] := [U("09B809BF09AE")]
Dict["singara"] := [U("09B809BF099909CD099709BE09B009BE")]
Dict["sir"] := [U("09B809CD09AF09BE09B0")]
Dict["siri"] := [U("09B809BF098109A109BC09BF")]
Dict["sit"] := [U("09B609C009A4")]
Dict["size"] := [U("09B809BE0987099C")]
Dict["sloo"] := [U("09B809CD09B209CB")]
Dict["slow"] := [U("09B809CD09B209CB")]
Dict["sob"] := [U("09B809AC")]
Dict["sobai"] := [U("09B809AC09BE0987")]
Dict["sobar"] := [U("09B809AC09BE09B0")]
Dict["sobay"] := [U("09B809AC09BE0987")]
Dict["sobji"] := [U("09B809AC099C09BF")]
Dict["sobjy"] := [U("09B809AC099C09BF")]
Dict["sobkichu"] := [U("09B809AC099509BF099B09C1")]
Dict["sobkicu"] := [U("09B809AC099509BF099B09C1")]
Dict["sobkisu"] := [U("09B809AC099509BF099B09C1")]
Dict["sobsomoi"] := [U("09B809AC09B809AE09AF09BC")]
Dict["sobsomoy"] := [U("09B809AC09B809AE09AF09BC")]
Dict["sobuj"] := [U("09B809AC09C1099C")]
Dict["sobuz"] := [U("09B809AC09C1099C")]
Dict["sobzi"] := [U("09B809AC099C09BF")]
Dict["software"] := [U("09B809AB099F099309AF09BC09CD09AF09BE09B0")]
Dict["sohoj"] := [U("09B809B9099C")]
Dict["sohoje"] := [U("09B809B9099C09C7")]
Dict["sohor"] := [U("09B609B909B0")]
Dict["sokal"] := [U("09B8099509BE09B2")]
Dict["soktisali"] := [U("09B6099509CD09A409BF09B609BE09B209C0")]
Dict["sokto"] := [U("09B6099509CD09A4")]
Dict["solo"] := [U("09B709CB09B209CB")]
Dict["somadhan"] := [U("09B809AE09BE09A709BE09A8")]
Dict["somaj"] := [U("09B809AE09BE099C")]
Dict["somaz"] := [U("09B809AE09BE099C")]
Dict["sombar"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["somoi"] := [U("09B809AE09AF09BC")]
Dict["somosa"] := [U("09B809AE09B809CD09AF09BE")]
Dict["somossa"] := [U("09B809AE09B809CD09AF09BE")]
Dict["somoy"] := [U("09B809AE09AF09BC")]
Dict["somuca"] := [U("09B809AE09C1099A09BE")]
Dict["somucha"] := [U("09B809AE09C1099A09BE")]
Dict["sonano"] := [U("09B609CB09A809BE09A809CB")]
Dict["sonda"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["sondha"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["sonibar"] := [U("09B609A809BF09AC09BE09B0")]
Dict["sontan"] := [U("09B809A809CD09A409BE09A8")]
Dict["sop"] := [U("09B609AA")]
Dict["sophtware"] := [U("09B809AB099F099309AF09BC09CD09AF09BE09B0")]
Dict["sopno"] := [U("09B809CD09AC09AA09CD09A8")]
Dict["soptaho"] := [U("09B809AA09CD09A409BE09B9")]
Dict["soptahw"] := [U("09B809AA09CD09A409BE09B9")]
Dict["sorir"] := [U("09B609B009C009B0")]
Dict["sorkar"] := [U("09B809B0099509BE09B0")]
Dict["sorot"] := [U("09B609B009CE")]
Dict["sorri"] := [U("09B809B009BF")]
Dict["sorry"] := [U("09B809B009BF")]
Dict["sory"] := [U("09B809B009BF")]
Dict["sosta"] := [U("09B809B809CD09A409BE")]
Dict["sostha"] := [U("09B809B809CD09A409BE")]
Dict["sosur"] := [U("09B609CD09AC09B609C109B0")]
Dict["sotero"] := [U("09B809A409C709B009CB")]
Dict["soterw"] := [U("09B809A409C709B009CB")]
Dict["sothik"] := [U("09B809A009BF0995")]
Dict["sotik"] := [U("09B809A009BF0995")]
Dict["sottor"] := [U("09B809A409CD09A409B0")]
Dict["sowroom"] := [U("09B609CB09B009C109AE")]
Dict["spam"] := [U("09B809CD09AA09CD09AF09BE09AE")]
Dict["speaker"] := [U("09B809CD09AA09BF099509BE09B0")]
Dict["speed"] := [U("09B809CD09AA09BF09A1")]
Dict["spid"] := [U("09B809CD09AA09BF09A1")]
Dict["spoon"] := [U("099A09BE09AE099A")]
Dict["spun"] := [U("099A09BE09AE099A")]
Dict["sri"] := [U("09B809B009BF")]
Dict["sry"] := [U("09B809B009BF")]
Dict["start"] := [U("09B809CD099F09BE09B009CD099F")]
Dict["station"] := [U("09B809CD099F09C709B609A8")]
Dict["stock"] := [U("09B809CD099F0995")]
Dict["stop"] := [U("09B809CD099F09AA")]
Dict["storage"] := [U("09B809CD099F09CB09B009C7099C")]
Dict["store"] := [U("09B809CD099F09CB09B0")]
Dict["stri"] := [U("09B809CD09A409CD09B009C0")]
Dict["stry"] := [U("09B809CD09A409CD09B009C0")]
Dict["student"] := [U("099B09BE09A409CD09B0")]
Dict["subhanalah"] := [U("09B809C109AC09B909BE09A809BE09B209CD09B209BE09B9")]
Dict["subhanallah"] := [U("09B809C109AC09B909BE09A809BE09B209CD09B209BE09B9")]
Dict["subhecha"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["subhechha"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["subho"] := [U("09B609C109AD")]
Dict["sud"] := [U("09B809C109A6")]
Dict["sudh"] := [U("09B809C109A6")]
Dict["suk"] := [U("09B809C10996")]
Dict["sukh"] := [U("09B809C10996")]
Dict["sukhi"] := [U("09B809C1099609C0")]
Dict["sukhy"] := [U("09B809C1099609C0")]
Dict["suki"] := [U("09B809C1099609C0")]
Dict["sukno"] := [U("09B609C1099509A809CB")]
Dict["sukrobar"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["sunben"] := [U("09B609C109A809AC09C709A8")]
Dict["sunbo"] := [U("09B609C109A809AC09CB")]
Dict["sunce"] := [U("09B609C109A8099B09C7")]
Dict["sunche"] := [U("09B609C109A8099B09C7")]
Dict["sunchi"] := [U("09B609C109A8099B09BF")]
Dict["sunci"] := [U("09B609C109A8099B09BF")]
Dict["sundai"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["sunday"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["sundor"] := [U("09B809C109A809CD09A609B0")]
Dict["sune"] := [U("09B609C109A809C7")]
Dict["suneche"] := [U("09B609C109A809C7099B09C7")]
Dict["sunechhe"] := [U("09B609C109A809C7099B09C7")]
Dict["sunechi"] := [U("09B609C109A809C7099B09BF")]
Dict["sunecho"] := [U("09B609C109A809C7099B09CB")]
Dict["suneci"] := [U("09B609C109A809C7099B09BF")]
Dict["suneco"] := [U("09B609C109A809C7099B09CB")]
Dict["suni"] := [U("09B609C109A809BF")]
Dict["suno"] := [U("09B609CB09A809CB")]
Dict["suplier"] := [U("09B809BE09AA09CD09B209BE09AF09BC09BE09B0")]
Dict["supplier"] := [U("09B809BE09AA09CD09B209BE09AF09BC09BE09B0")]
Dict["surjo"] := [U("09B809C209B009CD09AF")]
Dict["surjw"] := [U("09B809C209B009CD09AF")]
Dict["suru"] := [U("09B609C109B009C1")]
Dict["surzo"] := [U("09B809C209B009CD09AF")]
Dict["sustho"] := [U("09B809C109B809CD09A5")]
Dict["susthw"] := [U("09B809C109B809CD09A5")]
Dict["susto"] := [U("09B809C109B809CD09A5")]
Dict["suvanallah"] := [U("09B809C109AC09B909BE09A809BE09B209CD09B209BE09B9")]
Dict["table"] := [U("099F09C709AC09BF09B2")]
Dict["tader"] := [U("09A409BE09A609C709B0")]
Dict["tahole"] := [U("09A409BE09B909B209C7")]
Dict["tai"] := [U("09A409BE0987")]
Dict["taka"] := [U("099F09BE099509BE")]
Dict["takben"] := [U("09A509BE099509AC09C709A8")]
Dict["takbo"] := [U("09A509BE099509AC09CB")]
Dict["take"] := [U("09A509BE099509C7"), U("09A409BE099509C7")]
Dict["taki"] := [U("09A509BE099509BF")]
Dict["tako"] := [U("09A509BE099509CB")]
Dict["takte"] := [U("09A509BE099509A409C7")]
Dict["tanda"] := [U("09A009BE09A809CD09A109BE")]
Dict["tank"] := [U("099F09CD09AF09BE09820995")]
Dict["tanks"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["tap"] := [U("099F09CD09AF09BE09AA")]
Dict["tar"] := [U("09A409BE09B0")]
Dict["tara"] := [U("09A409BE09B009BE")]
Dict["taragari"] := [U("09A409BE09A109BC09BE09A409BE09A109BC09BF")]
Dict["taragary"] := [U("09A409BE09A109BC09BE09A409BE09A109BC09BF")]
Dict["tarik"] := [U("09A409BE09B009BF0996")]
Dict["tarikh"] := [U("09A409BE09B009BF0996")]
Dict["tbh"] := [U("099F09BF09AD09BF")]
Dict["te"] := [U("09A409C7")]
Dict["teacer"] := [U("09B609BF099509CD09B70995")]
Dict["teacher"] := [U("09B609BF099509CD09B70995")]
Dict["teke"] := [U("09A509C7099509C7")]
Dict["tel"] := [U("09A409C709B2")]
Dict["temon"] := [U("09A409C709AE09A8")]
Dict["tenshion"] := [U("099F09C709A809B609A8")]
Dict["tension"] := [U("099F09C709A809B609A8")]
Dict["tero"] := [U("09A409C709B009CB")]
Dict["terw"] := [U("09A409C709B009CB")]
Dict["tesht"] := [U("099F09C709B809CD099F")]
Dict["test"] := [U("099F09C709B809CD099F")]
Dict["thakben"] := [U("09A509BE099509AC09C709A8")]
Dict["thakbo"] := [U("09A509BE099509AC09CB")]
Dict["thakbw"] := [U("09A509BE099509AC09CB")]
Dict["thake"] := [U("09A509BE099509C7")]
Dict["thaki"] := [U("09A509BE099509BF")]
Dict["thako"] := [U("09A509BE099509CB")]
Dict["thakte"] := [U("09A509BE099509A409C7")]
Dict["thakw"] := [U("09A509BE099509CB")]
Dict["thaky"] := [U("09A509BE099509BF")]
Dict["thanda"] := [U("09A009BE09A809CD09A109BE")]
Dict["thanks"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["thanksh"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["theke"] := [U("09A509C7099509C7")]
Dict["thik"] := [U("09A009BF0995")]
Dict["thikana"] := [U("09A009BF099509BE09A809BE")]
Dict["thkbo"] := [U("09A509BE099509AC09CB")]
Dict["thkbw"] := [U("09A509BE099509AC09CB")]
Dict["thkte"] := [U("09A509BE099509A409C7")]
Dict["thnx"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["thursdai"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["thursday"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["thurshday"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["ticket"] := [U("099F09BF099509BF099F")]
Dict["tik"] := [U("09A009BF0995")]
Dict["tikana"] := [U("09A009BF099509BE09A809BE")]
Dict["tiktok"] := [U("099F09BF0995099F0995")]
Dict["time"] := [U("099F09BE098709AE")]
Dict["tin"] := [U("09A409BF09A8")]
Dict["tinbar"] := [U("09A409BF09A809AC09BE09B0")]
Dict["tk"] := [U("099F09BE099509BE")]
Dict["tkbo"] := [U("09A509BE099509AC09CB")]
Dict["tkte"] := [U("09A509BE099509A409C7")]
Dict["tnx"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["tobe"] := [U("09A409AC09C7")]
Dict["tobu"] := [U("09A409AC09C1")]
Dict["tobuo"] := [U("09A409AC09C10993")]
Dict["tokhn"] := [U("09A4099609A8")]
Dict["tokhon"] := [U("09A4099609A8")]
Dict["tokhoni"] := [U("09A4099609A80987")]
Dict["tokhono"] := [U("09A4099609A809CB")]
Dict["tokn"] := [U("09A4099609A8")]
Dict["tokon"] := [U("09A4099609A8")]
Dict["tomar"] := [U("09A409CB09AE09BE09B0")]
Dict["tomra"] := [U("09A409CB09AE09B009BE")]
Dict["total"] := [U("099F09CB099F09BE09B2")]
Dict["touc"] := [U("099F09BE099A")]
Dict["touch"] := [U("099F09BE099A")]
Dict["train"] := [U("099F09CD09B009C709A8")]
Dict["tri"] := [U("099F09CD09B009BE0987")]
Dict["tris"] := [U("09A409CD09B009BF09B6")]
Dict["trish"] := [U("09A409CD09B009BF09B6")]
Dict["tritiyo"] := [U("09A409C309A409C009AF09BC")]
Dict["tritiyw"] := [U("09A409C309A409C009AF09BC")]
Dict["truck"] := [U("099F09CD09B009BE0995")]
Dict["try"] := [U("099F09CD09B009BE0987")]
Dict["tuesdai"] := [U("09AE099909CD099709B209AC09BE09B0")]
Dict["tuesday"] := [U("09AE099909CD099709B209AC09BE09B0")]
Dict["tueshday"] := [U("09AE099909CD099709B209AC09BE09B0")]
Dict["tumi"] := [U("09A409C109AE09BF")]
Dict["tumy"] := [U("09A409C109AE09BF")]
Dict["tursday"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["tv"] := [U("099F09BF09AD09BF")]
Dict["unibhersity"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["unis"] := [U("098909A809BF09B6")]
Dict["unish"] := [U("098909A809BF09B6")]
Dict["univershity"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["universiti"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["university"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["upai"] := [U("098909AA09BE09AF09BC")]
Dict["upay"] := [U("098909AA09BE09AF09BC")]
Dict["update"] := [U("098609AA09A109C7099F")]
Dict["upload"] := [U("098609AA09B209CB09A1")]
Dict["uponash"] := [U("098909AA09A809CD09AF09BE09B8")]
Dict["uponnas"] := [U("098909AA09A809CD09AF09BE09B8")]
Dict["uponnash"] := [U("098909AA09A809CD09AF09BE09B8")]
Dict["upore"] := [U("098909AA09B009C7")]
Dict["ute"] := [U("098909A009C7")]
Dict["uthe"] := [U("098909A009C7")]
Dict["uthi"] := [U("098909A009BF")]
Dict["utho"] := [U("098909A009CB")]
Dict["uthw"] := [U("098909A009CB")]
Dict["uthy"] := [U("098909A009BF")]
Dict["uti"] := [U("098909A009BF")]
Dict["uto"] := [U("098909A009CB")]
Dict["vaat"] := [U("09AD09BE09A4")]
Dict["vabe"] := [U("09AD09BE09AC09C7")]
Dict["vabi"] := [U("09AD09BE09AC09BF")]
Dict["vabo"] := [U("09AD09BE09AC09CB")]
Dict["vai"] := [U("09AD09BE0987")]
Dict["vaiya"] := [U("09AD09BE098709AF09BC09BE")]
Dict["valo"] := [U("09AD09BE09B209CB")]
Dict["valobasha"] := [U("09AD09BE09B209CB09AC09BE09B809BE")]
Dict["van"] := [U("09AD09CD09AF09BE09A8")]
Dict["vasha"] := [U("09AD09BE09B709BE")]
Dict["vay"] := [U("09AD09BE0987")]
Dict["veja"] := [U("09AD09C7099C09BE")]
Dict["verifi"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["verify"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["veriphy"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["vershion"] := [U("09AD09BE09B009CD09B809A8")]
Dict["version"] := [U("09AD09BE09B009CD09B809A8")]
Dict["veza"] := [U("09AD09C7099C09BE")]
Dict["vid"] := [U("09AD09BF09A109BF0993")]
Dict["video"] := [U("09AD09BF09A109BF0993")]
Dict["videw"] := [U("09AD09BF09A109BF0993")]
Dict["visa"] := [U("09AD09BF09B809BE")]
Dict["visha"] := [U("09AD09BF09B809BE")]
Dict["vitore"] := [U("09AD09BF09A409B009C7")]
Dict["voi"] := [U("09AD09AF09BC")]
Dict["vor"] := [U("09AD09CB09B0")]
Dict["vote"] := [U("09AD09CB099F")]
Dict["voucer"] := [U("09AD09BE0989099A09BE09B0")]
Dict["voucher"] := [U("09AD09BE0989099A09BE09B0")]
Dict["voy"] := [U("09AD09AF09BC")]
Dict["vugol"] := [U("09AD09C2099709CB09B2")]
Dict["vul"] := [U("09AD09C109B2")]
Dict["wa"] := [U("09B909CB09AF09BC09BE099F09B8098509CD09AF09BE09AA")]
Dict["wait"] := [U("099309AF09BC09C7099F")]
Dict["walaikumasalam"] := [U("099309AF09BC09BE09B209BE0987099509C109AE0020098609B809B809BE09B209BE09AE")]
Dict["walaikumashsalam"] := [U("099309AF09BC09BE09B209BE0987099509C109AE0020098609B809B809BE09B209BE09AE")]
Dict["walaikumassalam"] := [U("099309AF09BC09BE09B209BE0987099509C109AE0020098609B809B809BE09B209BE09AE")]
Dict["warehouse"] := [U("099309AF09BC09CD09AF09BE09B009B909BE098909B8")]
Dict["warehoushe"] := [U("099309AF09BC09CD09AF09BE09B009B909BE098909B8")]
Dict["webshite"] := [U("099309AF09BC09C709AC09B809BE0987099F")]
Dict["website"] := [U("099309AF09BC09C709AC09B809BE0987099F")]
Dict["wednesdai"] := [U("09AC09C109A709AC09BE09B0")]
Dict["wednesday"] := [U("09AC09C109A709AC09BE09B0")]
Dict["wedneshday"] := [U("09AC09C109A709AC09BE09B0")]
Dict["weekend"] := [U("09890987099509C709A809CD09A1")]
Dict["whatsap"] := [U("09B909CB09AF09BC09BE099F09B8098509CD09AF09BE09AA")]
Dict["whatsapp"] := [U("09B909CB09AF09BC09BE099F09B8098509CD09AF09BE09AA")]
Dict["whatshapp"] := [U("09B909CB09AF09BC09BE099F09B8098509CD09AF09BE09AA")]
Dict["wholesale"] := [U("09B909CB09B209B809C709B2")]
Dict["wholeshale"] := [U("09B909CB09B209B809C709B2")]
Dict["wifi"] := [U("099309AF09BC09BE098709AB09BE0987")]
Dict["wify"] := [U("099309AF09BC09BE098709AB09BE0987")]
Dict["wikend"] := [U("09890987099509C709A809CD09A1")]
Dict["wiphi"] := [U("099309AF09BC09BE098709AB09BE0987")]
Dict["yes"] := [U("098709AF09BC09C709B8")]
Dict["yesh"] := [U("098709AF09BC09C709B8")]
Dict["youtube"] := [U("09870989099F09BF098909AC")]
Dict["yt"] := [U("09870989099F09BF098909AC")]
Dict["zabe"] := [U("09AF09BE09AC09C7")]
Dict["zaben"] := [U("09AF09BE09AC09C709A8")]
Dict["zabenna"] := [U("09AF09BE09AC09C709A8002009A809BE")]
Dict["zabo"] := [U("09AF09BE09AC09CB")]
Dict["zabona"] := [U("09AF09BE09AC09CB09A809BE")]
Dict["zachhe"] := [U("09AF09BE099A09CD099B09C7")]
Dict["zachhi"] := [U("09AF09BE099A09CD099B09BF")]
Dict["zachho"] := [U("09AF09BE099A09CD099B09CB")]
Dict["zagte"] := [U("099C09BE099709A409C7")]
Dict["zai"] := [U("09AF09BE0987")]
Dict["zake"] := [U("09AF09BE099509C7")]
Dict["zamai"] := [U("099C09BE09AE09BE0987")]
Dict["zan"] := [U("09AF09BE09A8")]
Dict["zanala"] := [U("099C09BE09A809BE09B209BE")]
Dict["zanben"] := [U("099C09BE09A809AC09C709A8")]
Dict["zanbo"] := [U("099C09BE09A809AC09CB")]
Dict["zanchi"] := [U("099C09BE09A8099B09BF")]
Dict["zane"] := [U("099C09BE09A809C7")]
Dict["zanen"] := [U("099C09BE09A809C709A8")]
Dict["zani"] := [U("099C09BE09A809BF")]
Dict["zano"] := [U("099C09BE09A809CB")]
Dict["zante"] := [U("099C09BE09A809A409C7")]
Dict["zao"] := [U("09AF09BE0993")]
Dict["zara"] := [U("09AF09BE09B009BE")]
Dict["zay"] := [U("09AF09BE09AF09BC")]
Dict["zazakalah"] := [U("099C09BE09AF09BE099509BE09B209CD09B209BE09B9")]
Dict["zazakallah"] := [U("099C09BE09AF09BE099509BE09B209CD09B209BE09B9")]
Dict["zbe"] := [U("09AF09BE09AC09C7")]
Dict["zbo"] := [U("09AF09BE09AC09CB")]
Dict["zege"] := [U("099C09C7099709C7")]
Dict["zete"] := [U("09AF09C709A409C7")]
Dict["zilapi"] := [U("099C09BF09B209BE09AA09BF")]
Dict["zinish"] := [U("099C09BF09A809BF09B8")]
Dict["zip"] := [U("099C09BF09AA")]
Dict["zira"] := [U("099C09BF09B009BE")]
Dict["znbo"] := [U("099C09BE09A809AC09CB")]
Dict["zni"] := [U("099C09BE09A809BF")]
Dict["znina"] := [U("099C09BE09A809BF09A809BE")]
Dict["zoin"] := [U("099C09AF09BC09C709A8")]
Dict["zonno"] := [U("099C09A809CD09AF")]
Dict["zonogon"] := [U("099C09A8099709A3")]
Dict["zore"] := [U("099C09CB09B009C7")]
Dict["zuddho"] := [U("09AF09C109A609CD09A7")]
Dict["amake"] := [U("098609AE09BE099509C7")]
Dict["amaka"] := [U("098609AE09BE099509C7")]
Dict["tomake"] := [U("09A409CB09AE09BE099509C7")]
Dict["tomaka"] := [U("09A409CB09AE09BE099509C7")]
Dict["apnake"] := [U("098609AA09A809BE099509C7")]
Dict["apnaka"] := [U("098609AA09A809BE099509C7")]
Dict["nijeka"] := [U("09A809BF099C09C7099509C7")]
Dict["onnoka"] := [U("098509A809CD09AF099509C7")]
Dict["jaka"] := [U("09AF09BE099509C7")]
Dict["amaderke"] := [U("098609AE09BE09A609C709B0099509C7")]
Dict["amaderka"] := [U("098609AE09BE09A609C709B0099509C7")]
Dict["tomader"] := [U("09A409CB09AE09BE09A609C709B0")]
Dict["tomaderke"] := [U("09A409CB09AE09BE09A609C709B0099509C7")]
Dict["tomaderka"] := [U("09A409CB09AE09BE09A609C709B0099509C7")]
Dict["taderke"] := [U("09A409BE09A609C709B0099509C7")]
Dict["taderka"] := [U("09A409BE09A609C709B0099509C7")]
Dict["apnader"] := [U("098609AA09A809BE09A609C709B0")]
Dict["apnaderke"] := [U("098609AA09A809BE09A609C709B0099509C7")]
Dict["apnaderka"] := [U("098609AA09A809BE09A609C709B0099509C7")]
Dict["jaba"] := [U("09AF09BE09AC09BE")]
Dict["zaba"] := [U("09AF09BE09AC09BE")]
Dict["khaba"] := [U("099609BE09AC09BE")]
Dict["korba"] := [U("099509B009AC09BE")]
Dict["ashba"] := [U("098609B809AC09BE")]
Dict["dekhba"] := [U("09A609C7099609AC09BE")]
Dict["bolba"] := [U("09AC09B209AC09BE")]
Dict["likhba"] := [U("09B209BF099609AC09BE")]
Dict["porba"] := [U("09AA09A109BC09AC09BE")]
Dict["shunba"] := [U("09B609C109A809AC09BE")]
Dict["thakba"] := [U("09A509BE099509AC09BE")]
Dict["cholba"] := [U("099A09B209AC09BE")]
Dict["parba"] := [U("09AA09BE09B009AC09BE")]
Dict["janba"] := [U("099C09BE09A809AC09BE")]
Dict["chaiba"] := [U("099A09BE098709AC09BE")]
Dict["diba"] := [U("09A609BF09AC09BE")]
Dict["niba"] := [U("09A809BF09AC09BE")]
Dict["kinba"] := [U("099509BF09A809AC09BE")]
Dict["bechba"] := [U("09AC09C7099A09AC09BE")]
Dict["banaba"] := [U("09AC09BE09A809BE09AC09BE")]
Dict["pathaba"] := [U("09AA09BE09A009BE09AC09BE")]
Dict["ghumaba"] := [U("099809C109AE09BE09AC09BE")]
Dict["uthba"] := [U("098909A009AC09BE")]
Dict["boshba"] := [U("09AC09B809AC09BE")]
Dict["khelba"] := [U("099609C709B209AC09BE")]
Dict["nachba"] := [U("09A809BE099A09AC09BE")]
Dict["gaiba"] := [U("099709BE098709AC09BE")]
Dict["hasba"] := [U("09B909BE09B809AC09BE")]
Dict["kandba"] := [U("099509BE098109A609AC09BE")]
Dict["hatba"] := [U("09B909BE0981099F09AC09BE")]
Dict["douraba"] := [U("09A609CC09A109BC09BE09AC09BE")]
Dict["shikhba"] := [U("09B609BF099609AC09BE")]
Dict["bujhba"] := [U("09AC09C1099D09AC09BE")]
Dict["bhabba"] := [U("09AD09BE09AC09AC09BE")]
Dict["rakba"] := [U("09B009BE099609AC09BE")]
Dict["firba"] := [U("09AB09BF09B009AC09BE")]
Dict["hoba"] := [U("09B909AC09BE")]
Dict["jaiba"] := [U("09AF09BE098709AC09BE")]
Dict["khaiba"] := [U("099609BE098709AC09BE")]
Dict["jabi"] := [U("09AF09BE09AC09BF")]
Dict["khabi"] := [U("099609BE09AC09BF")]
Dict["korbi"] := [U("099509B009AC09BF")]
Dict["ashbi"] := [U("098609B809AC09BF")]
Dict["dekhbi"] := [U("09A609C7099609AC09BF")]
Dict["bolbi"] := [U("09AC09B209AC09BF")]
Dict["likhbi"] := [U("09B209BF099609AC09BF")]
Dict["porbi"] := [U("09AA09A109BC09AC09BF")]
Dict["shunbi"] := [U("09B609C109A809AC09BF")]
Dict["thakbi"] := [U("09A509BE099509AC09BF")]
Dict["cholbi"] := [U("099A09B209AC09BF")]
Dict["parbi"] := [U("09AA09BE09B009AC09BF")]
Dict["janbi"] := [U("099C09BE09A809AC09BF")]
Dict["chaibi"] := [U("099A09BE098709AC09BF")]
Dict["dibi"] := [U("09A609BF09AC09BF")]
Dict["nibi"] := [U("09A809BF09AC09BF")]
Dict["kinbi"] := [U("099509BF09A809AC09BF")]
Dict["ghumabi"] := [U("099809C109AE09BE09AC09BF")]
Dict["uthbi"] := [U("098909A009AC09BF")]
Dict["boshbi"] := [U("09AC09B809AC09BF")]
Dict["khelbi"] := [U("099609C709B209AC09BF")]
Dict["hasbi"] := [U("09B909BE09B809AC09BF")]
Dict["kandbi"] := [U("099509BE098109A609AC09BF")]
Dict["shikhbi"] := [U("09B609BF099609AC09BF")]
Dict["bujhbi"] := [U("09AC09C1099D09AC09BF")]
Dict["firbi"] := [U("09AB09BF09B009AC09BF")]
Dict["hobi"] := [U("09B909AC09BF")]
Dict["korla"] := [U("099509B009B209BE"), U("099509B009B209C7")]
Dict["gela"] := [U("099709C709B209BE")]
Dict["gelo"] := [U("099709C709B209CB")]
Dict["ashla"] := [U("098609B809B209BE")]
Dict["khaila"] := [U("099609BE098709B209BE")]
Dict["dekhla"] := [U("09A609C7099609B209BE")]
Dict["bolla"] := [U("09AC09B209B209BE"), U("09AC09B209B209C7")]
Dict["likhla"] := [U("09B209BF099609B209BE")]
Dict["porla"] := [U("09AA09A109BC09B209BE")]
Dict["shunla"] := [U("09B609C109A809B209BE")]
Dict["janla"] := [U("099C09BE09A809B209BE")]
Dict["bujhla"] := [U("09AC09C1099D09B209BE")]
Dict["parla"] := [U("09AA09BE09B009B209BE")]
Dict["chaila"] := [U("099A09BE098709B209BE"), U("099A09BE098709B209C7")]
Dict["dila"] := [U("09A609BF09B209BE")]
Dict["nila"] := [U("09A809BF09B209BE")]
Dict["hoila"] := [U("09B9098709B209BE")]
Dict["thakla"] := [U("09A509BE099509B209BE")]
Dict["cholla"] := [U("099A09B209B209BE")]
Dict["a"] := [U("098F")]
Dict["aa"] := [U("0986")]
Dict["b"] := [U("09AC09BF")]
Dict["c"] := [U("09B809BF")]
Dict["d"] := [U("09A109BF")]
Dict["e"] := [U("0987")]
Dict["f"] := [U("098F09AB")]
Dict["g"] := [U("099C09BF")]
Dict["h"] := [U("098F0987099A")]
Dict["i"] := [U("09860987")]
Dict["j"] := [U("099C09C7")]
Dict["k"] := [U("099509C7")]
Dict["l"] := [U("098F09B2")]
Dict["m"] := [U("098F09AE")]
Dict["n"] := [U("098F09A8")]
Dict["p"] := [U("09AA09BF")]
Dict["q"] := [U("099509BF0989")]
Dict["s"] := [U("098F09B8")]
Dict["t"] := [U("099F09BF")]
Dict["u"] := [U("09870989")]
Dict["v"] := [U("09AD09BF")]
Dict["w"] := [U("09A109BE09AC09B209C1")]
Dict["x"] := [U("098F099509CD09B8")]
Dict["y"] := [U("099309AF09BC09BE0987")]
Dict["z"] := [U("099C09C709A1")]
Dict["dhakai"] := [U("09A209BE099509BE09AF09BC")]
Dict["dhakay"] := [U("09A209BE099509BE09AF09BC")]
Dict["sokala"] := [U("09B8099509BE09B209C7")]
Dict["thaka"] := [U("09A509C7099509C7")]
Dict["uata"] := [U("098909A009C7")]
Dict["protoma"] := [U("09AA09CD09B009A509AE09C7")]
Dict["tarpor"] := [U("09A409BE09B009AA09B0")]
Dict["khaa"] := [U("099609C709AF09BC09C7")]
Dict["kaja"] := [U("099509BE099C09C7")]
Dict["dai"] := [U("09A609BF0987")]
Dict["janta"] := [U("099C09BE09A809A409C7")]
Dict["sobi"] := [U("099B09AC09BF")]
Dict["maja"] := [U("09AE09BE099D09C7")]
Dict["cell"] := [U("09B809C709B2")]
Dict["bara"] := [U("09AC09C709A109BC09C7")]
Dict["kau"] := [U("099509C70989")]
Dict["poribara"] := [U("09AA09B009BF09AC09BE09B009C7")]
Dict["soto"] := [U("099B09CB099F")]
Dict["pora"] := [U("09AA09A109BC09C7")]
Dict["porikha"] := [U("09AA09B009C0099509CD09B709BE")]
Dict["kasa"] := [U("099509BE099B09C7")]
Dict["sondai"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["sondhay"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["aksata"] := [U("098F099509B809BE09A509C7")]
Dict["bosa"] := [U("09AC09B809C7")]
Dict["bondudar"] := [U("09AC09A809CD09A709C109A609C709B0")]
Dict["sata"] := [U("09B809BE09A509C7")]
Dict["rastai"] := [U("09B009BE09B809CD09A409BE09AF09BC")]
Dict["rastay"] := [U("09B009BE09B809CD09A409BE09AF09BC")]
Dict["gasar"] := [U("099709BE099B09C709B0")]
Dict["rata"] := [U("09B009BE09A409C7")]
Dict["utla"] := [U("098909A009B209C7")]
Dict["khob"] := [U("099609C109AC")]
Dict["akana"] := [U("098F099609BE09A809C7")]
Dict["soi"] := [U("099B09AF09BC")]
Dict["retu"] := [U("098B09A409C1")]
Dict["bisti"] := [U("09AC09C309B709CD099F09BF")]
Dict["hola"] := [U("09B909B209C7")]
Dict["joma"] := [U("099C09AE09C7")]
Dict["goroma"] := [U("099709B009AE09C7")]
Dict["kinto"] := [U("099509BF09A809CD09A409C1")]
Dict["sita"] := [U("09B609C009A409C7")]
Dict["kreshok"] := [U("099509C309B70995")]
Dict["foshol"] := [U("09AB09B809B2")]
Dict["folai"] := [U("09AB09B209BE09AF09BC")]
Dict["akdin"] := [U("098F099509A609BF09A8")]
Dict["babshai"] := [U("09AC09CD09AF09AC09B809BE09AF09BC09C0")]
Dict["shoj"] := [U("09B809B9099C")]
Dict["chasta"] := [U("099A09C709B709CD099F09BE")]
Dict["sikha"] := [U("09B609BF099509CD09B709BE")]
Dict["jibona"] := [U("099C09C009AC09A809C7")]
Dict["hoa"] := [U("09B9099309AF09BC09BE")]
Dict["ata"] := [U("098F099F09BE")]
Dict["bishas"] := [U("09AC09BF09B609CD09AC09BE09B8")]
Dict["kamon"] := [U("099509C709AE09A8")]
Dict["kotai"] := [U("099509CB09A509BE09AF09BC")]
Dict["asba"] := [U("098609B809AC09C7")]
Dict["anokdin"] := [U("098509A809C7099509A609BF09A8")]
Dict["dora"] := [U("09A709B009C7")]
Dict["akta"] := [U("098F0995099F09BE")]
Dict["dari"] := [U("09A609C709B009BF")]
Dict["opekha"] := [U("098509AA09C7099509CD09B709BE")]
Dict["sara"] := [U("09B809BE09B009BE"), U("099B09BE09A109BC09BE")]
Dict["kina"] := [U("099509BF09A809BE"), U("099509BF09A809C7")]
Dict["ano"] := [U("098609A809CB"), U("098F09A809CB")]
Dict["aca"] := [U("0986099B09C7")]
Dict["acha"] := [U("0986099B09C7")]
Dict["aga"] := [U("0986099709C7")]
Dict["ajka"] := [U("0986099C099509C7")]
Dict["asca"] := [U("098609B8099B09C7")]
Dict["ascha"] := [U("098609B8099B09C7")]
Dict["ashca"] := [U("098609B8099B09C7")]
Dict["ashcha"] := [U("098609B8099B09C7")]
Dict["ashta"] := [U("098609B809A409C7")]
Dict["asta"] := [U("098609B809CD09A409C7")]
Dict["azka"] := [U("0986099C099509C7")]
Dict["baira"] := [U("09AC09BE098709B009C7")]
Dict["baja"] := [U("09AC09BE099C09C7")]
Dict["banata"] := [U("09AC09BE09A809BE09A409C7")]
Dict["barba"] := [U("09AC09BE09A109BC09AC09C7")]
Dict["baza"] := [U("09AC09BE099C09C7")]
Dict["bechta"] := [U("09AC09C7099A09A409C7")]
Dict["becta"] := [U("09AC09C7099A09A409C7")]
Dict["bereca"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["berecha"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["bhaba"] := [U("09AD09BE09AC09C7")]
Dict["bhitora"] := [U("09AD09BF09A409B009C7")]
Dict["blta"] := [U("09AC09B209A409C7")]
Dict["bolca"] := [U("09AC09B2099B09C7")]
Dict["bolcha"] := [U("09AC09B2099B09C7")]
Dict["bola"] := [U("09AC09B209C7")]
Dict["bolecha"] := [U("09AC09B209C7099B09C7")]
Dict["bolechha"] := [U("09AC09B209C7099B09C7")]
Dict["bolta"] := [U("09AC09B209A409C7")]
Dict["bosha"] := [U("09AC09B809C7")]
Dict["bujha"] := [U("09AC09C1099D09C7")]
Dict["bujhecha"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bujhechha"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bujhta"] := [U("09AC09C1099D09A409C7")]
Dict["buzha"] := [U("09AC09C1099D09C7")]
Dict["buzhechha"] := [U("09AC09C1099D09C7099B09C7")]
Dict["buzhta"] := [U("09AC09C1099D09A409C7")]
Dict["caita"] := [U("099A09BE098709A409C7")]
Dict["cela"] := [U("099B09C709B209C7")]
Dict["chaita"] := [U("099A09BE098709A409C7")]
Dict["chela"] := [U("099B09C709B209C7")]
Dict["chola"] := [U("099A09B209C7")]
Dict["cholta"] := [U("099A09B209A409C7")]
Dict["cola"] := [U("099A09B209C7")]
Dict["colta"] := [U("099A09B209A409C7")]
Dict["dekcha"] := [U("09A609C70996099B09C7")]
Dict["deka"] := [U("09A609C7099609C7")]
Dict["dekechha"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhca"] := [U("09A609C70996099B09C7")]
Dict["dekhcha"] := [U("09A609C70996099B09C7")]
Dict["dekha"] := [U("09A609C7099609C7")]
Dict["dekhecha"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhechha"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhta"] := [U("09A609C7099609A409C7")]
Dict["dekta"] := [U("09A609C7099609A409C7")]
Dict["derita"] := [U("09A609C709B009BF09A409C7")]
Dict["dhira"] := [U("09A709C009B009C7")]
Dict["dhona"] := [U("09A709A809C7")]
Dict["dira"] := [U("09A709C009B009C7")]
Dict["dita"] := [U("09A609BF09A409C7")]
Dict["dkhta"] := [U("09A609C7099609A409C7")]
Dict["dkta"] := [U("09A609C7099609A409C7")]
Dict["dourata"] := [U("09A609CC09A109BC09BE09A409C7")]
Dict["dura"] := [U("09A609C209B009C7")]
Dict["ebhaba"] := [U("098F09AD09BE09AC09C7")]
Dict["abhabe"] := [U("098F09AD09BE09AC09C7")]
Dict["abong"] := [U("098F09AC0982")]
Dict["edika"] := [U("098F09A609BF099509C7")]
Dict["adike"] := [U("098F09A609BF099509C7")]
Dict["agaro"] := [U("098F099709BE09B009CB")]
Dict["agarw"] := [U("098F099709BE09B009CB")]
Dict["agula"] := [U("098F099709C109B209BE")]
Dict["agulo"] := [U("098F099709C109B209CB")]
Dict["eibhaba"] := [U("098F098709AD09BE09AC09C7")]
Dict["aibhabe"] := [U("098F098709AD09BE09AC09C7")]
Dict["aidik"] := [U("098F098709A609BF0995")]
Dict["aigula"] := [U("098F0987099709C109B209BE")]
Dict["aigulo"] := [U("098F0987099709C109B209CB")]
Dict["aijonno"] := [U("098F0987099C09A809CD09AF")]
Dict["aikhan"] := [U("098F0987099609BE09A8")]
Dict["eikhana"] := [U("098F0987099609BE09A809C7")]
Dict["aikhane"] := [U("098F0987099609BE09A809C7")]
Dict["aipash"] := [U("098F098709AA09BE09B6")]
Dict["aisob"] := [U("098F098709B809AC")]
Dict["aita"] := [U("098F0987099F09BE")]
Dict["aituku"] := [U("098F0987099F09C1099509C1")]
Dict["ajonno"] := [U("098F099C09A809CD09AF")]
Dict["ekana"] := [U("098F099609BE09A809C7")]
Dict["akane"] := [U("098F099609BE09A809C7")]
Dict["akbar"] := [U("098F099509AC09BE09B0")]
Dict["ekbara"] := [U("098F099509AC09BE09B009C7")]
Dict["akbare"] := [U("098F099509AC09BE09B009C7")]
Dict["ekhana"] := [U("098F099609BE09A809C7")]
Dict["akhane"] := [U("098F099609BE09A809C7")]
Dict["akhoni"] := [U("098F099609A80987")]
Dict["akhono"] := [U("098F099609A809CB")]
Dict["aki"] := [U("098F09950987")]
Dict["akjon"] := [U("098F0995099C09A8")]
Dict["akoi"] := [U("098F09950987")]
Dict["ekshatha"] := [U("098F099509B809BE09A509C7")]
Dict["akshathe"] := [U("098F099509B809BE09A509C7")]
Dict["aksho"] := [U("098F099509B609CB")]
Dict["akshw"] := [U("098F099509B609CB")]
Dict["akso"] := [U("098F099509B609CB")]
Dict["aktu"] := [U("098F0995099F09C1")]
Dict["aktuku"] := [U("098F0995099F09C1099609BE09A809BF")]
Dict["akzon"] := [U("098F0995099C09A8")]
Dict["amon"] := [U("098F09AE09A8")]
Dict["epasha"] := [U("098F09AA09BE09B609C7")]
Dict["apashe"] := [U("098F09AA09BE09B609C7")]
Dict["aror"] := [U("098F09B009B0")]
Dict["arror"] := [U("098F09B009B0")]
Dict["esa"] := [U("098F09B809C7")]
Dict["eseca"] := [U("098F09B809C7099B09C7")]
Dict["asece"] := [U("098F09B809C7099B09C7")]
Dict["esecha"] := [U("098F09B809C7099B09C7")]
Dict["aseche"] := [U("098F09B809C7099B09C7")]
Dict["esha"] := [U("098F09B809C7")]
Dict["esheca"] := [U("098F09B809C7099B09C7")]
Dict["ashece"] := [U("098F09B809C7099B09C7")]
Dict["eshecha"] := [U("098F09B809C7099B09C7")]
Dict["asheche"] := [U("098F09B809C7099B09C7")]
Dict["asia"] := [U("098F09B809C7")]
Dict["asob"] := [U("098F09B809AC")]
Dict["atai"] := [U("098F099F09BE0987")]
Dict["atobar"] := [U("098F09A409AC09BE09B0")]
Dict["atodin"] := [U("098F09A409A609BF09A8")]
Dict["atokhon"] := [U("098F09A4099509CD09B709A3")]
Dict["atokichu"] := [U("098F09A4099509BF099B09C1")]
Dict["atota"] := [U("098F09A4099F09BE")]
Dict["atotuku"] := [U("098F09A4099F09C1099509C1")]
Dict["axcange"] := [U("098F099509CD09B8099A09C7099E09CD099C")]
Dict["axchange"] := [U("098F099509CD09B8099A09C7099E09CD099C")]
Dict["fira"] := [U("09AB09BF09B009C7")]
Dict["firta"] := [U("09AB09BF09B009A409C7")]
Dict["gaita"] := [U("099709BE098709A409C7")]
Dict["geca"] := [U("099709C7099B09C7")]
Dict["gecha"] := [U("099709C7099B09C7")]
Dict["ghumata"] := [U("099809C109AE09BE09A409C7")]
Dict["giyecha"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["giyechha"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["hashta"] := [U("09B909BE09B809A409C7")]
Dict["hasta"] := [U("09B909BE09B809A409C7")]
Dict["hatta"] := [U("09B909BE0981099F09A409C7")]
Dict["hba"] := [U("09B909AC09C7")]
Dict["hocha"] := [U("09B9099A09CD099B09C7")]
Dict["hochha"] := [U("09B9099A09CD099B09C7")]
Dict["hoica"] := [U("09B90987099B09C7")]
Dict["hoicha"] := [U("09B90987099B09C7")]
Dict["hota"] := [U("09B909A409C7")]
Dict["hoyecha"] := [U("09B909AF09BC09C7099B09C7")]
Dict["hoyechha"] := [U("09B909AF09BC09C7099B09C7")]
Dict["jacha"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jachha"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jagta"] := [U("099C09BE099709A409C7")]
Dict["jana"] := [U("099C09BE09A809C7")]
Dict["jba"] := [U("09AF09BE09AC09C7")]
Dict["jega"] := [U("099C09C7099709C7")]
Dict["jena"] := [U("099C09C709A809C7")]
Dict["jeta"] := [U("09AF09C709A409C7")]
Dict["jora"] := [U("099C09CB09B009C7")]
Dict["kaca"] := [U("099509BE099B09C7")]
Dict["kacha"] := [U("099509BE099B09C7")]
Dict["kachha"] := [U("099609BE099A09CD099B09C7")]
Dict["kaka"] := [U("099509BE099509C7")]
Dict["kalka"] := [U("099509BE09B2099509C7")]
Dict["kanda"] := [U("099509BE098109A609C7")]
Dict["kandta"] := [U("099509BE098109A609A409C7")]
Dict["kelta"] := [U("099609C709B209A409C7")]
Dict["kemna"] := [U("099509C709AE09A809C7")]
Dict["keta"] := [U("099609C709A409C7")]
Dict["keyechha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khacha"] := [U("099609BE099A09CD099B09C7")]
Dict["khachha"] := [U("099609BE099A09CD099B09C7")]
Dict["khelta"] := [U("099609C709B209A409C7")]
Dict["kheta"] := [U("099609C709A409C7")]
Dict["kheyecha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kheyechha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kibhaba"] := [U("099509BF09AD09BE09AC09C7")]
Dict["kinta"] := [U("099509BF09A809A409C7")]
Dict["kivaba"] := [U("099509BF09AD09BE09AC09C7")]
Dict["koba"] := [U("099509AC09C7")]
Dict["komba"] := [U("099509AE09AC09C7")]
Dict["komeca"] := [U("099509AE09C7099B09C7")]
Dict["komecha"] := [U("099509AE09C7099B09C7")]
Dict["korca"] := [U("099509B0099B09C7")]
Dict["korecha"] := [U("099509B009C7099B09C7")]
Dict["korechha"] := [U("099509B009C7099B09C7")]
Dict["korta"] := [U("099509B009A409C7")]
Dict["krta"] := [U("099509B009A409C7")]
Dict["lagba"] := [U("09B209BE099709AC09C7")]
Dict["lagcha"] := [U("09B209BE0997099B09C7")]
Dict["laga"] := [U("09B209BE099709C7")]
Dict["lagsa"] := [U("09B209BE0997099B09C7")]
Dict["likcha"] := [U("09B209BF0996099B09C7")]
Dict["likechha"] := [U("09B209BF099609C7099B09C7")]
Dict["likhca"] := [U("09B209BF0996099B09C7")]
Dict["likhcha"] := [U("09B209BF0996099B09C7")]
Dict["likha"] := [U("09B209BF099609C7")]
Dict["likhecha"] := [U("09B209BF099609C7099B09C7")]
Dict["likhechha"] := [U("09B209BF099609C7099B09C7")]
Dict["likhta"] := [U("09B209BF099609A409C7")]
Dict["likta"] := [U("09B209BF099609A409C7")]
Dict["majha"] := [U("09AE09BE099D09C7")]
Dict["majhemajha"] := [U("09AE09BE099D09C709AE09BE099D09C7")]
Dict["mazha"] := [U("09AE09BE099D09C7")]
Dict["mazhemazha"] := [U("09AE09BE099D09C709AE09BE099D09C7")]
Dict["mona"] := [U("09AE09A809C7")]
Dict["nachta"] := [U("09A809BE099A09A409C7")]
Dict["nacta"] := [U("09A809BE099A09A409C7")]
Dict["nahola"] := [U("09A809BE09B909B209C7")]
Dict["nica"] := [U("09A809BF099A09C7")]
Dict["nicha"] := [U("09A809BF099A09C7")]
Dict["nija"] := [U("09A809BF099C09C7")]
Dict["nita"] := [U("09A809BF09A409C7")]
Dict["niza"] := [U("09A809BF099C09C7")]
Dict["nizeka"] := [U("09A809BF099C09C7099509C7")]
Dict["obhaba"] := [U("099309AD09BE09AC09C7")]
Dict["odika"] := [U("099309A609BF099509C7")]
Dict["oibhaba"] := [U("0993098709AD09BE09AC09C7")]
Dict["oikhana"] := [U("09930987099609BE09A809C7")]
Dict["okana"] := [U("0993099609BE09A809C7")]
Dict["okhana"] := [U("0993099609BE09A809C7")]
Dict["onoka"] := [U("098509A809CD09AF099509C7")]
Dict["opasha"] := [U("099309AA09BE09B609C7")]
Dict["para"] := [U("09AA09BE09B009C7")]
Dict["parta"] := [U("09AA09BE09B009A409C7")]
Dict["patata"] := [U("09AA09BE09A009BE09A409C7")]
Dict["pathata"] := [U("09AA09BE09A009BE09A409C7")]
Dict["phira"] := [U("09AB09BF09B009C7")]
Dict["phirta"] := [U("09AB09BF09B009A409C7")]
Dict["porca"] := [U("09AA09A109BC099B09C7")]
Dict["porcha"] := [U("09AA09A109BC099B09C7")]
Dict["porecha"] := [U("09AA09A109BC09C7099B09C7")]
Dict["porechha"] := [U("09AA09A109BC09C7099B09C7")]
Dict["porta"] := [U("09AA09A109BC09A409C7")]
Dict["prothoma"] := [U("09AA09CD09B009A509AE09C7")]
Dict["prta"] := [U("09AA09BE09B009A409C7")]
Dict["raka"] := [U("09B009BE099609C7")]
Dict["rakha"] := [U("09B009BE099609C7")]
Dict["satha"] := [U("09B809BE09A509C7")]
Dict["sebhab a"] := [U("09B809C709AD09BE09AC09C7")]
Dict["sedika"] := [U("09B809C709A609BF099509C7")]
Dict["seibhaba"] := [U("09B809C7098709AD09BE09AC09C7")]
Dict["seikhana"] := [U("09B809C70987099609BE09A809C7")]
Dict["sekana"] := [U("09B809C7099609BE09A809C7")]
Dict["sekhana"] := [U("09B809C7099609BE09A809C7")]
Dict["sepasha"] := [U("09B809C709AA09BE09B609C7")]
Dict["shatha"] := [U("09B809BE09A509C7")]
Dict["sha"] := [U("09B809C7")]
Dict["shekhana"] := [U("09B809C7099609BE09A809C7")]
Dict["shesha"] := [U("09B609C709B709C7")]
Dict["shika"] := [U("09B609BF099609C7")]
Dict["shikhta"] := [U("09B609BF099609A409C7")]
Dict["shikta"] := [U("09B609BF099609A409C7")]
Dict["shohoja"] := [U("09B809B9099C09C7")]
Dict["shohoza"] := [U("09B809B9099C09C7")]
Dict["shunca"] := [U("09B609C109A8099B09C7")]
Dict["shuncha"] := [U("09B609C109A8099B09C7")]
Dict["shuna"] := [U("09B609C109A809C7")]
Dict["shunecha"] := [U("09B609C109A809C7099B09C7")]
Dict["shunechha"] := [U("09B609C109A809C7099B09C7")]
Dict["sika"] := [U("09B609BF099609C7")]
Dict["sikhta"] := [U("09B609BF099609A409C7")]
Dict["sikta"] := [U("09B609BF099609A409C7")]
Dict["sohoja"] := [U("09B809B9099C09C7")]
Dict["sunca"] := [U("09B609C109A8099B09C7")]
Dict["suncha"] := [U("09B609C109A8099B09C7")]
Dict["suna"] := [U("09B609C109A809C7")]
Dict["sunecha"] := [U("09B609C109A809C7099B09C7")]
Dict["sunechha"] := [U("09B609C109A809C7099B09C7")]
Dict["tahola"] := [U("09A409BE09B909B209C7")]
Dict["takta"] := [U("09A509BE099509A409C7")]
Dict["teka"] := [U("09A509C7099509C7")]
Dict["thakta"] := [U("09A509BE099509A409C7")]
Dict["theka"] := [U("09A509C7099509C7")]
Dict["thkta"] := [U("09A509BE099509A409C7")]
Dict["tkta"] := [U("09A509BE099509A409C7")]
Dict["toba"] := [U("09A409AC09C7")]
Dict["upora"] := [U("098909AA09B009C7")]
Dict["uta"] := [U("098909A009C7")]
Dict["utha"] := [U("098909A009C7")]
Dict["vaba"] := [U("09AD09BE09AC09C7")]
Dict["vitora"] := [U("09AD09BF09A409B009C7")]
Dict["zachha"] := [U("09AF09BE099A09CD099B09C7")]
Dict["zagta"] := [U("099C09BE099709A409C7")]
Dict["zaka"] := [U("09AF09BE099509C7")]
Dict["zana"] := [U("099C09BE09A809C7")]
Dict["zanta"] := [U("099C09BE09A809A409C7")]
Dict["zba"] := [U("09AF09BE09AC09C7")]
Dict["zega"] := [U("099C09C7099709C7")]
Dict["zeta"] := [U("09AF09C709A409C7")]
Dict["zora"] := [U("099C09CB09B009C7")]
Dict["joto"] := [U("09AF09A4")]
Dict["jotoi"] := [U("09AF09A40987")]
Dict["jotodin"] := [U("09AF09A409A609BF09A8")]
Dict["jotokhon"] := [U("09AF09A4099509CD09B709A3")]
Dict["toto"] := [U("09A409A4")]
Dict["totoi"] := [U("09A409A40987")]
Dict["totodin"] := [U("09A409A409A609BF09A8")]
Dict["totokhon"] := [U("09A409A4099509CD09B709A3")]
Dict["tour"] := [U("099F09CD09AF09C109B0")]
Dict["tours"] := [U("099F09CD09AF09C109B0")]
Dict["travel"] := [U("099F09CD09B009BE09AD09C709B2")]
Dict["trip"] := [U("099F09CD09B009BF09AA")]
Dict["tor"] := [U("09A409CB09B0")]
Dict["tora"] := [U("09A409CB09B009BE")]
Dict["tore"] := [U("09A409CB09B009C7")]
Dict["ghurte"] := [U("099809C109B009A409C7")]
Dict["berate"] := [U("09AC09C709A109BC09BE09A409C7")]
Dict["bhromon"] := [U("09AD09CD09B009AE09A3")]
Dict["vromon"] := [U("09AD09CD09B009AE09A3")]
Dict["accout"] := [U("098509CD09AF09BE099509BE098909A809CD099F")]
Dict["acout"] := [U("098509CD09AF09BE099509BE098909A809CD099F")]
Dict["aget"] := [U("098F099C09C709A809CD099F")]
Dict["anodo"] := [U("098609A809A809CD09A6")]
Dict["anodw"] := [U("098609A809A809CD09A6")]
Dict["aterw"] := [U("098609A009BE09B009CB")]
Dict["ai"] := [U("098609AF09BC")]
Dict["barada"] := [U("09AC09BE09B009BE09A809CD09A609BE")]
Dict["bateri"] := [U("09AC09CD09AF09BE099F09BE09B009BF")]
Dict["batrum"] := [U("09AC09BE09A509B009C109AE")]
Dict["bacbo"] := [U("09AC09C7099A09AC09CB")]
Dict["bachbo"] := [U("09AC09C7099A09AC09CB")]
Dict["bachbw"] := [U("09AC09C7099A09AC09CB")]
Dict["bachi"] := [U("09AC09C7099A09BF")]
Dict["bachte"] := [U("09AC09C7099A09A409C7")]
Dict["bachy"] := [U("09AC09C7099A09BF")]
Dict["baci"] := [U("09AC09C7099A09BF")]
Dict["bacte"] := [U("09AC09C7099A09A409C7")]
Dict["bad"] := [U("099609BE099F")]
Dict["baguni"] := [U("09AC09C7099709C109A809BF")]
Dict["baguny"] := [U("09AC09C7099709C109A809BF")]
Dict["bai"] := [U("09AC09CD09AF09AF09BC")]
Dict["bakar"] := [U("09AC09C7099509BE09B0")]
Dict["barece"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["bareche"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["bashi"] := [U("09AC09C709B609BF")]
Dict["bashy"] := [U("09AC09C709B609BF")]
Dict["basi"] := [U("09AC09C709B609BF")]
Dict["baton"] := [U("09AC09C709A409A8")]
Dict["bay"] := [U("09AC09CD09AF09AF09BC")]
Dict["bhaja"] := [U("09AD09C7099C09BE")]
Dict["bherifi"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["bharify"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["bharsion"] := [U("09AD09BE09B009CD09B809A8")]
Dict["bizoi"] := [U("09AC09BF099C09AF09BC")]
Dict["bolese"] := [U("09AC09B209C7099B09C7")]
Dict["bodhu"] := [U("09AC09A809CD09A709C1")]
Dict["bonduto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bodhuto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bodhutto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bonduttw"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bodhuttw"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["bodu"] := [U("09AC09A809CD09A709C1")]
Dict["bodutto"] := [U("09AC09A809CD09A709C109A409CD09AC")]
Dict["boshoto"] := [U("09AC09B809A809CD09A4")]
Dict["bosoto"] := [U("09AC09B809A809CD09A4")]
Dict["bosotw"] := [U("09AC09B809A809CD09A4")]
Dict["brad"] := [U("09AC09CD09B009CD09AF09BE09A809CD09A1")]
Dict["buddy"] := [U("09AC09C109A609CD09A709BF")]
Dict["budi"] := [U("09AC09C109A609CD09A709BF")]
Dict["budiman"] := [U("09AC09C109A609CD09A709BF09AE09BE09A8")]
Dict["bujhese"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bushi"] := [U("09AC09CD09AF09B809CD09A4")]
Dict["buzhese"] := [U("09AC09C1099D09C7099B09C7")]
Dict["bya"] := [U("09AC09BE0987")]
Dict["caad"] := [U("099A09BE098109A6")]
Dict["caledar"] := [U("099509CD09AF09BE09B209C709A809CD09A109BE09B0")]
Dict["cack"] := [U("099A09C70995")]
Dict["cale"] := [U("099B09C709B209C7")]
Dict["caque"] := [U("099A09C70995")]
Dict["cartificate"] := [U("09B809BE09B009CD099F09BF09AB09BF099509C7099F")]
Dict["cartiphicate"] := [U("09B809BE09B009CD099F09BF09AB09BF099509C7099F")]
Dict["chaad"] := [U("099A09BE098109A6")]
Dict["chack"] := [U("099A09C70995")]
Dict["chale"] := [U("099B09C709B209C7")]
Dict["chaque"] := [U("099A09C70995")]
Dict["sad"] := [U("099B09BE09A6")]
Dict["satro"] := [U("099B09BE09A409CD09B0")]
Dict["satrw"] := [U("099B09BE09A409CD09B0")]
Dict["suti"] := [U("099B09C1099F09BF")]
Dict["suty"] := [U("099B09C1099F09BF")]
Dict["chita"] := [U("099A09BF09A809CD09A409BE")]
Dict["chity"] := [U("099A09BF09A009BF")]
Dict["cita"] := [U("099A09BF09A809CD09A409BE")]
Dict["citi"] := [U("099A09BF09A009BF")]
Dict["cok"] := [U("099A09CB0996")]
Dict["comet"] := [U("099509AE09C709A809CD099F")]
Dict["commet"] := [U("099509AE09C709A809CD099F")]
Dict["coi"] := [U("099B09AF09BC")]
Dict["cradit"] := [U("099509CD09B009C709A109BF099F")]
Dict["curet"] := [U("099509BE09B009C709A809CD099F")]
Dict["curret"] := [U("099509BE09B009C709A809CD099F")]
Dict["dara"] := [U("09A609BE098109A109BC09BE0993")]
Dict["da"] := [U("09A609BE0993")]
Dict["daaler"] := [U("09A109BF09B209BE09B0")]
Dict["daar"] := [U("09A109BF09AF09BC09BE09B0")]
Dict["dabit"] := [U("09A109C709AC09BF099F")]
Dict["dakano"] := [U("09A609C7099609BE09A809CB")]
Dict["dakben"] := [U("09A609C7099609AC09C709A8")]
Dict["dakbo"] := [U("09A609C7099609AC09CB")]
Dict["dakbona"] := [U("09A609C7099609AC09CB09A809BE")]
Dict["dakche"] := [U("09A609C70996099B09C7")]
Dict["dakchi"] := [U("09A609C70996099B09BF")]
Dict["dakcho"] := [U("09A609C70996099B09CB")]
Dict["dake"] := [U("09A609C7099609C7")]
Dict["dekese"] := [U("09A609C7099609C7099B09C7")]
Dict["dakechhe"] := [U("09A609C7099609C7099B09C7")]
Dict["dakechi"] := [U("09A609C7099609C7099B09BF")]
Dict["dakecho"] := [U("09A609C7099609C7099B09CB")]
Dict["dakhano"] := [U("09A609C7099609BE09A809CB")]
Dict["dekanw"] := [U("09A609C7099609BE09A809CB")]
Dict["dakhanw"] := [U("09A609C7099609BE09A809CB")]
Dict["dakhben"] := [U("09A609C7099609AC09C709A8")]
Dict["dakhbo"] := [U("09A609C7099609AC09CB")]
Dict["dakhbona"] := [U("09A609C7099609AC09CB09A809BE")]
Dict["dekbw"] := [U("09A609C7099609AC09CB")]
Dict["dakhbw"] := [U("09A609C7099609AC09CB")]
Dict["dekce"] := [U("09A609C70996099B09C7")]
Dict["dakhce"] := [U("09A609C70996099B09C7")]
Dict["dakhche"] := [U("09A609C70996099B09C7")]
Dict["dakhchi"] := [U("09A609C70996099B09BF")]
Dict["dakhcho"] := [U("09A609C70996099B09CB")]
Dict["dekchw"] := [U("09A609C70996099B09CB")]
Dict["dakhchw"] := [U("09A609C70996099B09CB")]
Dict["dekchy"] := [U("09A609C70996099B09BF")]
Dict["dakhchy"] := [U("09A609C70996099B09BF")]
Dict["dekci"] := [U("09A609C70996099B09BF")]
Dict["dakhci"] := [U("09A609C70996099B09BF")]
Dict["dekco"] := [U("09A609C70996099B09CB")]
Dict["dakhco"] := [U("09A609C70996099B09CB")]
Dict["dakhe"] := [U("09A609C7099609C7")]
Dict["dekeche"] := [U("09A609C7099609C7099B09C7")]
Dict["dakheche"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhese"] := [U("09A609C7099609C7099B09C7")]
Dict["dakhechhe"] := [U("09A609C7099609C7099B09C7")]
Dict["dakhechi"] := [U("09A609C7099609C7099B09BF")]
Dict["dakhecho"] := [U("09A609C7099609C7099B09CB")]
Dict["dekechw"] := [U("09A609C7099609C7099B09CB")]
Dict["dakhechw"] := [U("09A609C7099609C7099B09CB")]
Dict["dekechy"] := [U("09A609C7099609C7099B09BF")]
Dict["dakhechy"] := [U("09A609C7099609C7099B09BF")]
Dict["dekeci"] := [U("09A609C7099609C7099B09BF")]
Dict["dakheci"] := [U("09A609C7099609C7099B09BF")]
Dict["dekeco"] := [U("09A609C7099609C7099B09CB")]
Dict["dakheco"] := [U("09A609C7099609C7099B09CB")]
Dict["dakhi"] := [U("09A609C7099609BF")]
Dict["dekia"] := [U("09A609C7099609C7")]
Dict["dakhia"] := [U("09A609C7099609C7")]
Dict["dakho"] := [U("09A609C7099609CB")]
Dict["dakhte"] := [U("09A609C7099609A409C7")]
Dict["dakhun"] := [U("09A609C7099609C109A8")]
Dict["dekw"] := [U("09A609C7099609CB")]
Dict["dakhw"] := [U("09A609C7099609CB")]
Dict["deky"] := [U("09A609C7099609BF")]
Dict["dakhy"] := [U("09A609C7099609BF")]
Dict["daki"] := [U("09A609C7099609BF")]
Dict["dako"] := [U("09A609C7099609CB")]
Dict["dakte"] := [U("09A609C7099609A409C7")]
Dict["dakun"] := [U("09A609C7099609C109A8")]
Dict["delibheri"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["dalibhery"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["daliveri"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["dalivery"] := [U("09A109C709B209BF09AD09BE09B009BF")]
Dict["darite"] := [U("09A609C709B009BF09A409C7")]
Dict["das"] := [U("09A609C709B6")]
Dict["dash"] := [U("09A609C709B6")]
Dict["dashign"] := [U("09A109BF099C09BE098709A8")]
Dict["dasign"] := [U("09A109BF099C09BE098709A8")]
Dict["day"] := [U("09A609C709AF09BC")]
Dict["donobad"] := [U("09A709A809CD09AF09AC09BE09A6")]
Dict["dushor"] := [U("09A709C209B809B0")]
Dict["discout"] := [U("09A109BF09B8099509BE098909A809CD099F")]
Dict["dishcout"] := [U("09A109BF09B8099509BE098909A809CD099F")]
Dict["dishplai"] := [U("09A109BF09B809AA09CD09B209C7")]
Dict["dkbw"] := [U("09A609C7099609AC09CB")]
Dict["dky"] := [U("09A609C7099609BF")]
Dict["documet"] := [U("09A1099509C109AE09C709A809CD099F")]
Dict["donload"] := [U("09A109BE098909A809B209CB09A1")]
Dict["duki"] := [U("09A609C10983099609C0")]
Dict["duko"] := [U("09A609C109830996")]
Dict["dukkw"] := [U("09A609C109830996")]
Dict["dukky"] := [U("09A609C10983099609C0")]
Dict["eikan"] := [U("098F0987099609BE09A8")]
Dict["eikane"] := [U("098F0987099609BE09A809C7")]
Dict["ekoni"] := [U("098F099609A80987")]
Dict["ekono"] := [U("098F099609A809CB")]
Dict["ekshate"] := [U("098F099509B809BE09A509C7")]
Dict["etokon"] := [U("098F09A4099509CD09B709A3")]
Dict["farmaci"] := [U("09AB09BE09B009CD09AE09C709B809BF")]
Dict["farri"] := [U("09AB09C709B009BF")]
Dict["farry"] := [U("09AB09C709B009BF")]
Dict["feri"] := [U("09AB09C709B009BF")]
Dict["fary"] := [U("09AB09C709B009BF")]
Dict["follo"] := [U("09AB09B209CB")]
Dict["folloer"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["folo"] := [U("09AB09B209CB")]
Dict["foloer"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["fotocopi"] := [U("09AB099F09CB099509AA09BF")]
Dict["frae"] := [U("09AB09CD09B009BF")]
Dict["frd"] := [U("09AC09A809CD09A709C1")]
Dict["galeri"] := [U("099709CD09AF09BE09B209BE09B009BF")]
Dict["ga"] := [U("099709BE0993")]
Dict["gace"] := [U("099709C7099B09C7")]
Dict["gache"] := [U("099709C7099B09C7")]
Dict["ghae"] := [U("099809BF")]
Dict["ghuma"] := [U("099809C109AE09BE0993")]
Dict["giyese"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["godon"] := [U("099709C109A609BE09AE")]
Dict["haadfone"] := [U("09B909C709A109AB09CB09A8")]
Dict["haadphone"] := [U("09B909C709A109AB09CB09A8")]
Dict["hallo"] := [U("09B909CD09AF09BE09B209CB")]
Dict["hallw"] := [U("09B909CD09AF09BE09B209CB")]
Dict["halo"] := [U("09B909CD09AF09BE09B209CB")]
Dict["hemoto"] := [U("09B909C709AE09A809CD09A4")]
Dict["hamonto"] := [U("09B909C709AE09A809CD09A4")]
Dict["hemotw"] := [U("09B909C709AE09A809CD09A4")]
Dict["hamontw"] := [U("09B909C709AE09A809CD09A4")]
Dict["hose"] := [U("09B9099A09CD099B09C7")]
Dict["hotat"] := [U("09B909A009BE09CE")]
Dict["hoyese"] := [U("09B909AF09BC09C7099B09C7")]
Dict["iteresht"] := [U("098709A809CD099F09BE09B009C709B809CD099F")]
Dict["iterest"] := [U("098709A809CD099F09BE09B009C709B809CD099F")]
Dict["iternet"] := [U("098709A809CD099F09BE09B009A809C7099F")]
Dict["jase"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jasi"] := [U("09AF09BE099A09CD099B09BF")]
Dict["jaso"] := [U("09AF09BE099A09CD099B09CB")]
Dict["jasw"] := [U("09AF09BE099A09CD099B09CB")]
Dict["jasy"] := [U("09AF09BE099A09CD099B09BF")]
Dict["jate"] := [U("099C09BE09A809A409C7")]
Dict["ja"] := [U("09AF09BE0993")]
Dict["jage"] := [U("099C09C7099709C7")]
Dict["jamon"] := [U("09AF09C709AE09A8")]
Dict["jaya"] := [U("09AF09C709AF09BC09C7")]
Dict["jaye"] := [U("09AF09C709AF09BC09C7")]
Dict["juddw"] := [U("09AF09C109A609CD09A7")]
Dict["judo"] := [U("09AF09C109A609CD09A7")]
Dict["kase"] := [U("099609BE099A09CD099B09C7")]
Dict["kadbo"] := [U("099509BE098109A609AC09CB")]
Dict["kadbw"] := [U("099509BE098109A609AC09CB")]
Dict["kade"] := [U("099509BE098109A609C7")]
Dict["kadte"] := [U("099509BE098109A609A409C7")]
Dict["kaoa"] := [U("099609BE099309AF09BC09BE")]
Dict["ka"] := [U("099509C7")]
Dict["kajur"] := [U("099609C7099C09C109B0")]
Dict["kalbo"] := [U("099609C709B209AC09CB")]
Dict["kale"] := [U("099609C709B209C7")]
Dict["kali"] := [U("099609C709B209BF")]
Dict["kalte"] := [U("099609C709B209A409C7")]
Dict["kamne"] := [U("099509C709AE09A809C7")]
Dict["kano"] := [U("099509C709A8")]
Dict["kanw"] := [U("099509C709A8")]
Dict["kate"] := [U("099609C709A409C7")]
Dict["kauna"] := [U("099509C70989002009A809BE")]
Dict["kaw"] := [U("099509C70989")]
Dict["kayboard"] := [U("099509BF09AC09CB09B009CD09A1")]
Dict["keyese"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kayechhe"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kayechi"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["kayecho"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["kabw"] := [U("099609BE09AC09CB")]
Dict["khase"] := [U("099609BE099A09CD099B09C7")]
Dict["kachhy"] := [U("099609BE099A09CD099B09BF")]
Dict["khasy"] := [U("099609BE099A09CD099B09BF")]
Dict["kachi"] := [U("099609BE099A09CD099B09BF")]
Dict["kaia"] := [U("099609C709AF09BC09C7")]
Dict["khaoa"] := [U("099609BE099309AF09BC09BE")]
Dict["kashy"] := [U("099609BE09B809BF")]
Dict["kha"] := [U("099609BE0993")]
Dict["kbw"] := [U("099609BE09AC09CB")]
Dict["keia"] := [U("099609C709AF09BC09C7")]
Dict["khajur"] := [U("099609C7099C09C109B0")]
Dict["khalbo"] := [U("099609C709B209AC09CB")]
Dict["kelbw"] := [U("099609C709B209AC09CB")]
Dict["khalbw"] := [U("099609C709B209AC09CB")]
Dict["khale"] := [U("099609C709B209C7")]
Dict["khali"] := [U("099609C709B209BF")]
Dict["khalo"] := [U("099609C709B209CB")]
Dict["khalte"] := [U("099609C709B209A409C7")]
Dict["kelw"] := [U("099609C709B209CB")]
Dict["khalw"] := [U("099609C709B209CB")]
Dict["kely"] := [U("099609C709B209BF")]
Dict["khaly"] := [U("099609C709B209BF")]
Dict["khate"] := [U("099609C709A409C7")]
Dict["keya"] := [U("099609C709AF09BC09C7")]
Dict["khaya"] := [U("099609C709AF09BC09C7")]
Dict["keye"] := [U("099609C709AF09BC09C7")]
Dict["khaye"] := [U("099609C709AF09BC09C7")]
Dict["keyeche"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khayeche"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kheyese"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khayechhe"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khayechi"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["khayecho"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["keyechw"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["khayechw"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["keyechy"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["khayechy"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["keyeci"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["khayeci"] := [U("099609C709AF09BC09C7099B09BF")]
Dict["keyeco"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["khayeco"] := [U("099609C709AF09BC09C7099B09CB")]
Dict["kezur"] := [U("099609C7099C09C109B0")]
Dict["khazur"] := [U("099609C7099C09C109B0")]
Dict["kichury"] := [U("099609BF099A09C109A109BC09BF")]
Dict["kicuri"] := [U("099609BF099A09C109A109BC09BF")]
Dict["koroc"] := [U("099609B0099A")]
Dict["kushy"] := [U("099609C109B609BF")]
Dict["kite"] := [U("099509BF09A809A409C7")]
Dict["kitu"] := [U("099509BF09A809CD09A409C1")]
Dict["klati"] := [U("099509CD09B209BE09A809CD09A409BF")]
Dict["klato"] := [U("099509CD09B209BE09A809CD09A4")]
Dict["klatw"] := [U("099509CD09B209BE09A809CD09A4")]
Dict["klaty"] := [U("099509CD09B209BE09A809CD09A409BF")]
Dict["kokonoy"] := [U("0995099609A809CB0987")]
Dict["kokonw"] := [U("0995099609A809CB")]
Dict["korese"] := [U("099509B009C7099B09C7")]
Dict["labu"] := [U("09B209C709AC09C1")]
Dict["likese"] := [U("09B209BF099609C7099B09C7")]
Dict["likbw"] := [U("09B209BF099609AC09CB")]
Dict["likce"] := [U("09B209BF0996099B09C7")]
Dict["likchy"] := [U("09B209BF0996099B09BF")]
Dict["likci"] := [U("09B209BF0996099B09BF")]
Dict["likeche"] := [U("09B209BF099609C7099B09C7")]
Dict["likhese"] := [U("09B209BF099609C7099B09C7")]
Dict["likechw"] := [U("09B209BF099609C7099B09CB")]
Dict["likechy"] := [U("09B209BF099609C7099B09BF")]
Dict["likeci"] := [U("09B209BF099609C7099B09BF")]
Dict["likeco"] := [U("09B209BF099609C7099B09CB")]
Dict["likia"] := [U("09B209BF099609C7")]
Dict["likun"] := [U("09B209BF099609C109A8")]
Dict["likw"] := [U("09B209BF099609CB")]
Dict["liky"] := [U("09B209BF099609BF")]
Dict["magh"] := [U("09AE09C70998")]
Dict["maia"] := [U("09AE09C709AF09BC09C7")]
Dict["mamber"] := [U("09AE09C709AE09CD09AC09BE09B0")]
Dict["mamori"] := [U("09AE09C709AE09CB09B009BF")]
Dict["mamory"] := [U("09AE09C709AE09CB09B009BF")]
Dict["masage"] := [U("09AE09C709B809C7099C")]
Dict["masenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["mashsage"] := [U("09AE09C709B809C7099C")]
Dict["mashsenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["massage"] := [U("09AE09C709B809C7099C")]
Dict["massenger"] := [U("09AE09C709B809C7099E09CD099C09BE09B0")]
Dict["maya"] := [U("09AE09C709AF09BC09C7")]
Dict["maye"] := [U("09AE09C709AF09BC09C7")]
Dict["modai"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["moday"] := [U("09B809CB09AE09AC09BE09B0")]
Dict["motri"] := [U("09AE09A809CD09A409CD09B009C0")]
Dict["motry"] := [U("09AE09A809CD09A409CD09B009C0")]
Dict["nat"] := [U("09A809C7099F")]
Dict["nata"] := [U("09A809C709A409BE")]
Dict["obhinodon"] := [U("098509AD09BF09A809A809CD09A609A8")]
Dict["oikan"] := [U("09930987099609BE09A8")]
Dict["oikane"] := [U("09930987099609BE09A809C7")]
Dict["osadaron"] := [U("098509B809BE09A709BE09B009A3")]
Dict["osato"] := [U("098509B609BE09A809CD09A4")]
Dict["oshato"] := [U("098509B609BE09A809CD09A4")]
Dict["oshatw"] := [U("098509B609BE09A809CD09A4")]
Dict["oshushto"] := [U("098509B809C109B809CD09A5")]
Dict["oshustw"] := [U("098509B809C109B809CD09A5")]
Dict["osud"] := [U("099309B709C109A7")]
Dict["osusto"] := [U("098509B809C109B809CD09A5")]
Dict["otokon"] := [U("098509A4099509CD09B709A3")]
Dict["ovinodon"] := [U("098509AD09BF09A809A809CD09A609A8")]
Dict["patabw"] := [U("09AA09BE09A009BE09AC09CB")]
Dict["pataw"] := [U("09AA09BE09A009BE0993")]
Dict["patha"] := [U("09AA09BE09A009BE0993")]
Dict["patay"] := [U("09AA09BE09A009BE0987")]
Dict["paymet"] := [U("09AA09C709AE09C709A809CD099F")]
Dict["parmit"] := [U("09AA09BE09B009AE09BF099F")]
Dict["payaj"] := [U("09AA09C7098109AF09BC09BE099C")]
Dict["payara"] := [U("09AA09C709AF09BC09BE09B009BE")]
Dict["payaz"] := [U("09AA09C7098109AF09BC09BE099C")]
Dict["phactori"] := [U("09AB09CD09AF09BE099509CD099F09B009BF")]
Dict["pherri"] := [U("09AB09C709B009BF")]
Dict["pharry"] := [U("09AB09C709B009BF")]
Dict["phollo"] := [U("09AB09B209CB")]
Dict["pholloer"] := [U("09AB09B209CB09AF09BC09BE09B0")]
Dict["phrae"] := [U("09AB09CD09B009BF")]
Dict["phridai"] := [U("09B609C1099509CD09B009AC09BE09B0")]
Dict["phrd"] := [U("09AC09A809CD09A709C1")]
Dict["plaase"] := [U("09AA09CD09B209BF099C")]
Dict["plaashe"] := [U("09AA09CD09B209BF099C")]
Dict["pola"] := [U("09AA09CB09B209BE0993")]
Dict["porazoi"] := [U("09AA09B009BE099C09AF09BC")]
Dict["porsi"] := [U("09AA09A109BC099B09BF")]
Dict["porsy"] := [U("09AA09A109BC099B09BF")]
Dict["porese"] := [U("09AA09A109BC09C7099B09C7")]
Dict["prit"] := [U("09AA09CD09B009BF09A809CD099F")]
Dict["prodanmotri"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["prodhanmotri"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["prodanmontry"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["prodhanmotry"] := [U("09AA09CD09B009A709BE09A809AE09A809CD09A409CD09B009C0")]
Dict["protome"] := [U("09AA09CD09B009A509AE09C7")]
Dict["rakw"] := [U("09B009BE099609CB")]
Dict["raky"] := [U("09B009BE099609BF")]
Dict["raac"] := [U("09B009BF099A")]
Dict["raach"] := [U("09B009BF099A")]
Dict["raadi"] := [U("09B009C709A109BF")]
Dict["raady"] := [U("09B009C709A109BF")]
Dict["raceipt"] := [U("09B009B809BF09A6")]
Dict["refud"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["rafund"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["rephud"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["raphund"] := [U("09B009BF09AB09BE09A809CD09A1")]
Dict["rapli"] := [U("09B009BF09AA09CD09B209BE0987")]
Dict["raply"] := [U("09B009BF09AA09CD09B209BE0987")]
Dict["raport"] := [U("09B009BF09AA09CB09B009CD099F")]
Dict["rashtart"] := [U("09B009BF09B809CD099F09BE09B009CD099F")]
Dict["reshtaurat"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["rashtaurant"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["rastart"] := [U("09B009BF09B809CD099F09BE09B009CD099F")]
Dict["restaurat"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["rastaurant"] := [U("09B009C709B809CD099F09C109B009C709A809CD099F")]
Dict["ratail"] := [U("09B009BF099F09C7098709B2")]
Dict["raturn"] := [U("09B009BF099F09BE09B009CD09A8")]
Dict["ricksa"] := [U("09B009BF099509B609BE")]
Dict["ricksha"] := [U("09B009BF099509B609BE")]
Dict["sadinota"] := [U("09B809CD09AC09BE09A709C009A809A409BE")]
Dict["sades"] := [U("09B809A809CD09A609C709B6")]
Dict["sadesh"] := [U("09B809A809CD09A609C709B6")]
Dict["sati"] := [U("09B609BE09A809CD09A409BF")]
Dict["sato"] := [U("09B609BE09A809CD09A4")]
Dict["sasto"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["scraen"] := [U("09B809CD099509CD09B009BF09A8")]
Dict["scraenshot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["scraensot"] := [U("09B809CD099509CD09B009BF09A809B6099F")]
Dict["sa"] := [U("09B809C7")]
Dict["saarc"] := [U("09B809BE09B009CD099A")]
Dict["saarch"] := [U("09B809BE09B009CD099A")]
Dict["sabhab e"] := [U("09B809C709AD09BE09AC09C7")]
Dict["sadike"] := [U("09B809C709A609BF099509C7")]
Dict["sagula"] := [U("09B809C7099709C109B209BE")]
Dict["sagulo"] := [U("09B809C7099709C109B209CB")]
Dict["sai"] := [U("09B809C70987")]
Dict["saibhabe"] := [U("09B809C7098709AD09BE09AC09C7")]
Dict["saidik"] := [U("09B809C7098709A609BF0995")]
Dict["saijonno"] := [U("09B809C70987099C09A809CD09AF")]
Dict["seikan"] := [U("09B809C70987099609BE09A8")]
Dict["saikhan"] := [U("09B809C70987099609BE09A8")]
Dict["seikane"] := [U("09B809C70987099609BE09A809C7")]
Dict["saikhane"] := [U("09B809C70987099609BE09A809C7")]
Dict["saipash"] := [U("09B809C7098709AA09BE09B6")]
Dict["saisob"] := [U("09B809C7098709B809AC")]
Dict["saita"] := [U("09B809C70987099F09BE")]
Dict["sajonno"] := [U("09B809C7099C09A809CD09AF")]
Dict["saka"] := [U("09B609C7099609BE")]
Dict["sakane"] := [U("09B809C7099609BE09A809C7")]
Dict["sakha"] := [U("09B609C7099609BE")]
Dict["sakhane"] := [U("09B809C7099609BE09A809C7")]
Dict["sal"] := [U("09B809C709B2")]
Dict["sall"] := [U("09B809C709B2")]
Dict["sed"] := [U("09B809C709A809CD09A1")]
Dict["sand"] := [U("09B809C709A809CD09A1")]
Dict["sapashe"] := [U("09B809C709AA09BE09B609C7")]
Dict["sas"] := [U("09B609C709B7")]
Dict["sasob"] := [U("09B809C709B809AC")]
Dict["satai"] := [U("09B809C7099F09BE0987")]
Dict["sating"] := [U("09B809C7099F09BF0982")]
Dict["satings"] := [U("09B809C7099F09BF098209B8")]
Dict["satting"] := [U("09B809C7099F09BF0982")]
Dict["sattings"] := [U("09B809C7099F09BF098209B8")]
Dict["shalari"] := [U("09B809CD09AF09BE09B209BE09B009BF")]
Dict["shadesh"] := [U("09B809A809CD09A609C709B6")]
Dict["shati"] := [U("09B609BE09A809CD09A409BF")]
Dict["shato"] := [U("09B609BE09A809CD09A4")]
Dict["shatw"] := [U("09B609BE09A809CD09A4")]
Dict["shaty"] := [U("09B609BE09A809CD09A409BF")]
Dict["shashto"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shastw"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["shate"] := [U("09B809BE09A509C7")]
Dict["shatei"] := [U("09B809BE09A509C70987")]
Dict["shaturdai"] := [U("09B609A809BF09AC09BE09B0")]
Dict["shaarch"] := [U("09B809BE09B009CD099A")]
Dict["shaka"] := [U("09B609C7099609BE")]
Dict["shakha"] := [U("09B609C7099609BE")]
Dict["shekane"] := [U("09B809C7099609BE09A809C7")]
Dict["shakhane"] := [U("09B809C7099609BE09A809C7")]
Dict["shall"] := [U("09B809C709B2")]
Dict["shed"] := [U("09B809C709A809CD09A1")]
Dict["shand"] := [U("09B809C709A809CD09A1")]
Dict["shash"] := [U("09B609C709B7")]
Dict["shashe"] := [U("09B609C709B709C7")]
Dict["shatting"] := [U("09B809C7099F09BF0982")]
Dict["shattingsh"] := [U("09B809C7099F09BF098209B8")]
Dict["shikbw"] := [U("09B609BF099609AC09CB")]
Dict["shiky"] := [U("09B609BF099609BF")]
Dict["shlo"] := [U("09B809CD09B209CB")]
Dict["shonda"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["shodha"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["shotan"] := [U("09B809A809CD09A409BE09A8")]
Dict["shorri"] := [U("09B809B009BF")]
Dict["shotik"] := [U("09B809A009BF0995")]
Dict["shoroom"] := [U("09B609CB09B009C109AE")]
Dict["shorum"] := [U("09B609CB09B009C109AE")]
Dict["shpaaker"] := [U("09B809CD09AA09BF099509BE09B0")]
Dict["shpaed"] := [U("09B809CD09AA09BF09A1")]
Dict["shri"] := [U("09B809B009BF")]
Dict["shtudet"] := [U("099B09BE09A409CD09B0")]
Dict["shubhesa"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["shud"] := [U("09B809C109A6")]
Dict["shuk"] := [U("09B809C10996")]
Dict["shuki"] := [U("09B809C1099609C0")]
Dict["shundai"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["shuday"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["shudor"] := [U("09B809C109A809CD09A609B0")]
Dict["shunese"] := [U("09B609C109A809C7099B09C7")]
Dict["shushto"] := [U("09B809C109B809CD09A5")]
Dict["shuvesa"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["slo"] := [U("09B809CD09B209CB")]
Dict["somadan"] := [U("09B809AE09BE09A709BE09A8")]
Dict["soda"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["sodha"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["sotan"] := [U("09B809A809CD09A409BE09A8")]
Dict["sori"] := [U("09B809B009BF")]
Dict["soroom"] := [U("09B609CB09B009C109AE")]
Dict["spaaker"] := [U("09B809CD09AA09BF099509BE09B0")]
Dict["spaed"] := [U("09B809CD09AA09BF09A1")]
Dict["studet"] := [U("099B09BE09A409CD09B0")]
Dict["subhesa"] := [U("09B609C109AD09C7099A09CD099B09BE")]
Dict["suky"] := [U("09B809C1099609C0")]
Dict["sudai"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["suday"] := [U("09B009AC09BF09AC09BE09B0")]
Dict["sudor"] := [U("09B809C109A809CD09A609B0")]
Dict["sunese"] := [U("09B609C109A809C7099B09C7")]
Dict["sustw"] := [U("09B809C109B809CD09A5")]
Dict["tada"] := [U("09A009BE09A809CD09A109BE")]
Dict["ta"] := [U("09A409C7")]
Dict["taacer"] := [U("09B609BF099509CD09B70995")]
Dict["taacher"] := [U("09B609BF099509CD09B70995")]
Dict["tal"] := [U("09A409C709B2")]
Dict["tamon"] := [U("09A409C709AE09A8")]
Dict["tanshion"] := [U("099F09C709A809B609A8")]
Dict["tansion"] := [U("099F09C709A809B609A8")]
Dict["taro"] := [U("09A409C709B009CB")]
Dict["tarw"] := [U("09A409C709B009CB")]
Dict["tasht"] := [U("099F09C709B809CD099F")]
Dict["tast"] := [U("099F09C709B809CD099F")]
Dict["takbw"] := [U("09A509BE099509AC09CB")]
Dict["takw"] := [U("09A509BE099509CB")]
Dict["taky"] := [U("09A509BE099509BF")]
Dict["thada"] := [U("09A009BE09A809CD09A109BE")]
Dict["tanksh"] := [U("09A509CD09AF09BE0982099509B8")]
Dict["tkbw"] := [U("09A509BE099509AC09CB")]
Dict["tursdai"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["turshday"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["thurshdai"] := [U("09AC09C309B909B809CD09AA09A409BF09AC09BE09B0")]
Dict["tokoni"] := [U("09A4099609A80987")]
Dict["tokono"] := [U("09A4099609A809CB")]
Dict["tueshdai"] := [U("09AE099909CD099709B209AC09BE09B0")]
Dict["unibhersiti"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["univershiti"] := [U("09AC09BF09B609CD09AC09AC09BF09A609CD09AF09BE09B209AF09BC")]
Dict["utw"] := [U("098909A009CB")]
Dict["uty"] := [U("098909A009BF")]
Dict["vaja"] := [U("09AD09C7099C09BE")]
Dict["varifi"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["varify"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["veriphi"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["variphy"] := [U("09AD09C709B009BF09AB09BE0987")]
Dict["varshion"] := [U("09AD09BE09B009CD09B809A8")]
Dict["varsion"] := [U("09AD09BE09B009CD09B809A8")]
Dict["vaza"] := [U("09AD09C7099C09BE")]
Dict["vide"] := [U("09AD09BF09A109BF0993")]
Dict["wabshite"] := [U("099309AF09BC09C709AC09B809BE0987099F")]
Dict["wabsite"] := [U("099309AF09BC09C709AC09B809BE0987099F")]
Dict["wadnesdai"] := [U("09AC09C109A709AC09BE09B0")]
Dict["wadnesday"] := [U("09AC09C109A709AC09BE09B0")]
Dict["wedneshdai"] := [U("09AC09C109A709AC09BE09B0")]
Dict["wadneshday"] := [U("09AC09C109A709AC09BE09B0")]
Dict["weeked"] := [U("09890987099509C709A809CD09A1")]
Dict["waekend"] := [U("09890987099509C709A809CD09A1")]
Dict["wiked"] := [U("09890987099509C709A809CD09A1")]
Dict["yas"] := [U("098709AF09BC09C709B8")]
Dict["yash"] := [U("098709AF09BC09C709B8")]
Dict["zase"] := [U("09AF09BE099A09CD099B09C7")]
Dict["zasi"] := [U("09AF09BE099A09CD099B09BF")]
Dict["zaso"] := [U("09AF09BE099A09CD099B09CB")]
Dict["zate"] := [U("099C09BE09A809A409C7")]
Dict["zage"] := [U("099C09C7099709C7")]
Dict["zuddo"] := [U("09AF09C109A609CD09A7")]
Dict["kaba"] := [U("099609BE09AC09BE")]
Dict["dekba"] := [U("09A609C7099609AC09BE")]
Dict["dakhba"] := [U("09A609C7099609AC09BE")]
Dict["likba"] := [U("09B209BF099609AC09BE")]
Dict["takba"] := [U("09A509BE099509AC09BE")]
Dict["bachba"] := [U("09AC09C7099A09AC09BE")]
Dict["pataba"] := [U("09AA09BE09A009BE09AC09BE")]
Dict["utba"] := [U("098909A009AC09BE")]
Dict["kelba"] := [U("099609C709B209AC09BE")]
Dict["khalba"] := [U("099609C709B209AC09BE")]
Dict["kadba"] := [U("099509BE098109A609AC09BE")]
Dict["shikba"] := [U("09B609BF099609AC09BE")]
Dict["kaiba"] := [U("099609BE098709AC09BE")]
Dict["kabi"] := [U("099609BE09AC09BF")]
Dict["dekbi"] := [U("09A609C7099609AC09BF")]
Dict["dakhbi"] := [U("09A609C7099609AC09BF")]
Dict["likbi"] := [U("09B209BF099609AC09BF")]
Dict["takbi"] := [U("09A509BE099509AC09BF")]
Dict["utbi"] := [U("098909A009AC09BF")]
Dict["kelbi"] := [U("099609C709B209AC09BF")]
Dict["khalbi"] := [U("099609C709B209AC09BF")]
Dict["kadbi"] := [U("099509BE098109A609AC09BF")]
Dict["shikbi"] := [U("09B609BF099609AC09BF")]
Dict["gala"] := [U("099709C709B209BE")]
Dict["galo"] := [U("099709C709B209CB")]
Dict["kaila"] := [U("099609BE098709B209BE")]
Dict["dekla"] := [U("09A609C7099609B209BE")]
Dict["dakhla"] := [U("09A609C7099609B209BE")]
Dict["likla"] := [U("09B209BF099609B209BE")]
Dict["takla"] := [U("09A509BE099509B209BE")]
Dict["dakai"] := [U("09A209BE099509BE09AF09BC")]
Dict["dakay"] := [U("09A209BE099509BE09AF09BC")]
Dict["kaa"] := [U("099609C709AF09BC09C7")]
Dict["jata"] := [U("099C09BE09A809A409C7")]
Dict["porika"] := [U("09AA09B009C0099509CD09B709BE")]
Dict["sodai"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["sonday"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["sondhai"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["sodhay"] := [U("09B809A809CD09A709CD09AF09BE09AF09BC")]
Dict["bodudar"] := [U("09AC09A809CD09A709C109A609C709B0")]
Dict["kob"] := [U("099609C109AC")]
Dict["ratu"] := [U("098B09A409C1")]
Dict["kito"] := [U("099509BF09A809CD09A409C1")]
Dict["krashok"] := [U("099509C309B70995")]
Dict["opeka"] := [U("098509AA09C7099509CD09B709BE")]
Dict["bachta"] := [U("09AC09C7099A09A409C7")]
Dict["bacta"] := [U("09AC09C7099A09A409C7")]
Dict["bareca"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["barecha"] := [U("09AC09C709A109BC09C7099B09C7")]
Dict["bolesa"] := [U("09AC09B209C7099B09C7")]
Dict["bujhesa"] := [U("09AC09C1099D09C7099B09C7")]
Dict["buzhesa"] := [U("09AC09C1099D09C7099B09C7")]
Dict["cala"] := [U("099B09C709B209C7")]
Dict["chala"] := [U("099B09C709B209C7")]
Dict["dakcha"] := [U("09A609C70996099B09C7")]
Dict["dekesa"] := [U("09A609C7099609C7099B09C7")]
Dict["dakechha"] := [U("09A609C7099609C7099B09C7")]
Dict["dekca"] := [U("09A609C70996099B09C7")]
Dict["dakhca"] := [U("09A609C70996099B09C7")]
Dict["dakhcha"] := [U("09A609C70996099B09C7")]
Dict["dakha"] := [U("09A609C7099609C7")]
Dict["dekecha"] := [U("09A609C7099609C7099B09C7")]
Dict["dakhecha"] := [U("09A609C7099609C7099B09C7")]
Dict["dekhesa"] := [U("09A609C7099609C7099B09C7")]
Dict["dakhechha"] := [U("09A609C7099609C7099B09C7")]
Dict["dakhta"] := [U("09A609C7099609A409C7")]
Dict["dakta"] := [U("09A609C7099609A409C7")]
Dict["darita"] := [U("09A609C709B009BF09A409C7")]
Dict["dona"] := [U("09A709A809C7")]
Dict["aikan"] := [U("098F0987099609BE09A8")]
Dict["eikana"] := [U("098F0987099609BE09A809C7")]
Dict["aikane"] := [U("098F0987099609BE09A809C7")]
Dict["akoni"] := [U("098F099609A80987")]
Dict["akono"] := [U("098F099609A809CB")]
Dict["ekshata"] := [U("098F099509B809BE09A509C7")]
Dict["akshate"] := [U("098F099509B809BE09A509C7")]
Dict["atokon"] := [U("098F09A4099509CD09B709A3")]
Dict["gaca"] := [U("099709C7099B09C7")]
Dict["gacha"] := [U("099709C7099B09C7")]
Dict["giyesa"] := [U("099709BF09AF09BC09C7099B09C7")]
Dict["hosa"] := [U("09B9099A09CD099B09C7")]
Dict["hoyesa"] := [U("09B909AF09BC09C7099B09C7")]
Dict["jasa"] := [U("09AF09BE099A09CD099B09C7")]
Dict["jaga"] := [U("099C09C7099709C7")]
Dict["kada"] := [U("099509BE098109A609C7")]
Dict["kadta"] := [U("099509BE098109A609A409C7")]
Dict["kalta"] := [U("099609C709B209A409C7")]
Dict["kamna"] := [U("099509C709AE09A809C7")]
Dict["keyesa"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kayechha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khasa"] := [U("099609BE099A09CD099B09C7")]
Dict["khalta"] := [U("099609C709B209A409C7")]
Dict["keyecha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khayecha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kheyesa"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["khayechha"] := [U("099609C709AF09BC09C7099B09C7")]
Dict["kita"] := [U("099509BF09A809A409C7")]
Dict["koresa"] := [U("099509B009C7099B09C7")]
Dict["likesa"] := [U("09B209BF099609C7099B09C7")]
Dict["likca"] := [U("09B209BF0996099B09C7")]
Dict["lika"] := [U("09B209BF099609C7")]
Dict["likecha"] := [U("09B209BF099609C7099B09C7")]
Dict["likhesa"] := [U("09B209BF099609C7099B09C7")]
Dict["oikana"] := [U("09930987099609BE09A809C7")]
Dict["poresa"] := [U("09AA09A109BC09C7099B09C7")]
Dict["sabhab a"] := [U("09B809C709AD09BE09AC09C7")]
Dict["sadika"] := [U("09B809C709A609BF099509C7")]
Dict["saibhaba"] := [U("09B809C7098709AD09BE09AC09C7")]
Dict["seikana"] := [U("09B809C70987099609BE09A809C7")]
Dict["saikhana"] := [U("09B809C70987099609BE09A809C7")]
Dict["sakana"] := [U("09B809C7099609BE09A809C7")]
Dict["sakhana"] := [U("09B809C7099609BE09A809C7")]
Dict["sapasha"] := [U("09B809C709AA09BE09B609C7")]
Dict["shata"] := [U("09B809BE09A509C7")]
Dict["shekana"] := [U("09B809C7099609BE09A809C7")]
Dict["shakhana"] := [U("09B809C7099609BE09A809C7")]
Dict["shasha"] := [U("09B609C709B709C7")]
Dict["shunesa"] := [U("09B609C109A809C7099B09C7")]
Dict["sunesa"] := [U("09B609C109A809C7099B09C7")]
Dict["zasa"] := [U("09AF09BE099A09CD099B09C7")]
Dict["zata"] := [U("099C09BE09A809A409C7")]
Dict["zaga"] := [U("099C09C7099709C7")]
Dict["jotokon"] := [U("09AF09A4099509CD09B709A3")]
Dict["totokon"] := [U("09A409A4099509CD09B709A3")]
Dict["barate"] := [U("09AC09C709A109BC09BE09A409C7")]
Dict["aikana"] := [U("098F0987099609BE09A809C7")]
Dict["akshata"] := [U("098F099509B809BE09A509C7")]
Dict["barata"] := [U("09AC09C709A109BC09BE09A409C7")]
Dict["kisu"] := [U("099509BF099B09C1")]
Dict["jokon"] := [U("09AF099609A8")]
Dict["jokoni"] := [U("09AF099609A80987")]
Dict["jokhoni"] := [U("09AF099609A80987")]
Dict["rocket"] := [U("09B0099509C7099F")]
Dict["booking"] := [U("09AC09C1099509BF0982")]
Dict["warranty"] := [U("099309AF09BC09BE09B009C709A809CD099F09BF")]
Dict["guarantee"] := [U("099709CD09AF09BE09B009BE09A809CD099F09BF")]
Dict["lab"] := [U("09B209BE09AD")]
Dict["bikala"] := [U("09AC09BF099509C709B209C7")]
Dict["bikele"] := [U("09AC09BF099509C709B209C7")]
Dict["sele"] := [U("099B09C709B209C7")]
Dict["boss"] := [U("09AC09B8")]
Dict["meeting"] := [U("09AE09BF099F09BF0982")]
Dict["bosor"] := [U("09AC099B09B0")]
Dict["pasa"] := [U("09AA09BE09B609C7")]
Dict["songa"] := [U("09B8099909CD099709C7")]
Dict["songe"] := [U("09B8099909CD099709C7")]
Dict["khelna"] := [U("099609C709B209A809BE")]
Dict["english"] := [U("0987098209B209BF09B6")]
Dict["result"] := [U("09B009C7099C09BE09B209CD099F")]
Dict["fail"] := [U("09AB09C709B2")]
Dict["sesa"] := [U("09B609C709B709C7")]
Dict["akbara"] := [U("098F099509AC09BE09B009C7")]
Dict["lomba"] := [U("09B209AE09CD09AC09BE")]
Dict["khato"] := [U("099609BE099F09CB")]
Dict["mota"] := [U("09AE09CB099F09BE")]
Dict["dorkar"] := [U("09A609B0099509BE09B0")]
Dict["proyojon"] := [U("09AA09CD09B009AF09BC09CB099C09A8")]
Dict["issa"] := [U("0987099A09CD099B09BE")]
Dict["sondeho"] := [U("09B809A809CD09A609C709B9")]
Dict["mitta"] := [U("09AE09BF09A509CD09AF09BE")]
Dict["sotto"] := [U("09B809A409CD09AF")]
Dict["sotyo"] := [U("09B809A409CD09AF")]
Dict["prosno"] := [U("09AA09CD09B009B609CD09A8")]
Dict["jiggasa"] := [U("099C09BF099C09CD099E09BE09B809BE")]
Dict["utbo"] := [U("098909A009AC09CB")]
Dict["bosbo"] := [U("09AC09B809AC09CB")]
Dict["bujbo"] := [U("09AC09C1099D09AC09CB")]
Dict["rakbo"] := [U("09B009BE099609AC09CB")]
Dict["sunba"] := [U("09B609C109A809AC09BE")]
Dict["sikba"] := [U("09B609BF099609AC09BE")]
Dict["bujba"] := [U("09AC09C1099D09AC09BE")]
Dict["math"] := [U("09AE09BE09A0")]
Dict["pukhur"] := [U("09AA09C1099509C109B0")]
Dict["pukur"] := [U("09AA09C1099509C109B0")]
Dict["meg"] := [U("09AE09C70998")]
Dict["majhrat"] := [U("09AE09BE099D09B009BE09A4")]
Dict["ghonta"] := [U("099809A309CD099F09BE")]
Dict["minute"] := [U("09AE09BF09A809BF099F")]
Dict["second"] := [U("09B809C7099509C709A809CD09A1")]
Dict["friend"] := [U("09AB09CD09B009C709A809CD09A1")]
Dict["money"] := [U("099F09BE099509BE")]
Dict["service"] := [U("09B809BE09B009CD09AD09BF09B8")]
Dict["support"] := [U("09B809BE09AA09CB09B009CD099F")]
Dict["network"] := [U("09A809C7099F099309AF09BC09BE09B009CD0995")]
Dict["signal"] := [U("09B809BF099709A809CD09AF09BE09B2")]
Dict["mouse"] := [U("09AE09BE098909B8")]
Dict["house"] := [U("09AC09BE09A109BC09BF")]
Dict["road"] := [U("09B009BE09B809CD09A409BE")]
Dict["city"] := [U("09B609B909B0")]
Dict["village"] := [U("099709CD09B009BE09AE")]
Dict["country"] := [U("09A609C709B6")]
Dict["world"] := [U("09AC09BF09B609CD09AC")]
Dict["evening"] := [U("09B809A809CD09A709CD09AF09BE")]
Dict["today"] := [U("0986099C")]
Dict["tomorrow"] := [U("0986099709BE09AE09C0099509BE09B2")]
Dict["yesterday"] := [U("099709A4099509BE09B2")]
Dict["week"] := [U("09B809AA09CD09A409BE09B9")]
Dict["month"] := [U("09AE09BE09B8")]
Dict["year"] := [U("09AC099B09B0")]
Dict["happy"] := [U("09B909CD09AF09BE09AA09BF")]
Dict["birthday"] := [U("099C09A809CD09AE09A609BF09A8")]
Dict["love"] := [U("09AD09BE09B209CB09AC09BE09B809BE")]
Dict["life"] := [U("099C09C009AC09A8")]
Dict["work"] := [U("099509BE099C")]
Dict["job"] := [U("099A09BE099509B009BF")]
Dict["manager"] := [U("09AE09CD09AF09BE09A809C7099C09BE09B0")]
Dict["team"] := [U("099F09BF09AE")]
Dict["class"] := [U("099509CD09B209BE09B8")]
Dict["exam"] := [U("09AA09B009C0099509CD09B709BE")]
Dict["book"] := [U("09AC0987")]
Dict["pen"] := [U("099509B209AE")]
Dict["door"] := [U("09A609B0099C09BE")]
Dict["window"] := [U("099C09BE09A809BE09B209BE")]
Dict["food"] := [U("099609BE09AC09BE09B0")]
Dict["rice"] := [U("09AD09BE09A4")]
Dict["tea"] := [U("099A09BE")]
Dict["water"] := [U("09AA09BE09A809BF")]
Dict["milk"] := [U("09A609C109A7")]
Dict["fruit"] := [U("09AB09B2")]
Dict["fish"] := [U("09AE09BE099B")]
Dict["meat"] := [U("09AE09BE098209B8")]
Dict["chicken"] := [U("09AE09C109B0099709BF")]
Dict["egg"] := [U("09A109BF09AE")]
Dict["welcome"] := [U("09B809CD09AC09BE099709A409AE")]
Dict["new"] := [U("09A809A409C109A8")]
Dict["old"] := [U("09AA09C109B009BE09A809CB")]
Dict["big"] := [U("09AC09A109BC")]
Dict["small"] := [U("099B09CB099F")]
Dict["hot"] := [U("099709B009AE")]
Dict["cold"] := [U("09A009BE09A809CD09A109BE")]
Dict["easy"] := [U("09B809B9099C")]
Dict["hard"] := [U("099509A009BF09A8")]
Dict["right"] := [U("09A009BF0995")]
Dict["wrong"] := [U("09AD09C109B2")]
Dict["true"] := [U("09B809A409CD09AF")]
Dict["false"] := [U("09AE09BF09A509CD09AF09BE")]
Dict["no"] := [U("09A809BE")]
Dict["question"] := [U("09AA09CD09B009B609CD09A8")]
Dict["answer"] := [U("098909A409CD09A409B0")]
Dict["problem"] := [U("09B809AE09B809CD09AF09BE")]
Dict["solution"] := [U("09B809AE09BE09A709BE09A8")]
Dict["help"] := [U("09B809BE09B909BE09AF09CD09AF")]
Dict["idea"] := [U("0986098709A109BF09AF09BC09BE")]
Dict["plan"] := [U("09AA09CD09B209CD09AF09BE09A8")]
Dict["project"] := [U("09AA09CD09B0099C09C7099509CD099F")]
Dict["save"] := [U("09B809C709AD")]
Dict["delete"] := [U("09A109BF09B209BF099F")]
Dict["edit"] := [U("098F09A109BF099F")]
Dict["user"] := [U("09870989099C09BE09B0")]
Dict["channel"] := [U("099A09CD09AF09BE09A809C709B2")]
Dict["story"] := [U("09B809CD099F09CB09B009BF")]
Dict["status"] := [U("09B809CD099F09CD09AF09BE099F09BE09B8")]
Dict["bio"] := [U("09AC09BE09AF09BC09CB")]
Dict["banner"] := [U("09AC09CD09AF09BE09A809BE09B0")]
Dict["logo"] := [U("09B209CB099709CB")]
Dict["mall"] := [U("09AE09B2")]
Dict["medicine"] := [U("099309B709C109A7")]
Dict["health"] := [U("09B809CD09AC09BE09B809CD09A509CD09AF")]
Dict["gym"] := [U("099C09BF09AE")]
Dict["sport"] := [U("099609C709B209BE")]
Dict["match"] := [U("09AE09CD09AF09BE099A")]
Dict["player"] := [U("099609C709B209CB09AF09BC09BE09A109BC")]
Dict["goal"] := [U("099709CB09B2")]
Dict["win"] := [U("099C09AF09BC")]
Dict["lose"] := [U("09B909BE09B0")]
Dict["news"] := [U("09A809BF0989099C")]
Dict["radio"] := [U("09B009C709A109BF0993")]
Dict["newspaper"] := [U("09AA09A409CD09B009BF099509BE")]
Dict["magazine"] := [U("09AE09CD09AF09BE099709BE099C09BF09A8")]
Dict["movie"] := [U("09B809BF09A809C709AE09BE")]
Dict["song"] := [U("099709BE09A8")]
Dict["music"] := [U("09AE09BF0989099C09BF0995")]
Dict["dance"] := [U("09A809BE099A")]
Dict["drama"] := [U("09A809BE099F0995")]
Dict["actor"] := [U("098509AD09BF09A809C709A409BE")]
Dict["actress"] := [U("098509AD09BF09A809C709A409CD09B009C0")]
Dict["singer"] := [U("099709BE09AF09BC0995")]
Dict["artist"] := [U("09B609BF09B209CD09AA09C0")]
Dict["writer"] := [U("09B209C709960995")]
Dict["poet"] := [U("099509AC09BF")]
Dict["engineer"] := [U("0987099E09CD099C09BF09A809BF09AF09BC09BE09B0")]
Dict["lawyer"] := [U("0989099509BF09B2")]
Dict["army"] := [U("09B809C709A809BE09AC09BE09B909BF09A809C0")]
Dict["government"] := [U("09B809B0099509BE09B0")]
Dict["minister"] := [U("09AE09A809CD09A409CD09B009C0")]
Dict["president"] := [U("09B009BE09B709CD099F09CD09B009AA09A409BF")]
Dict["election"] := [U("09A809BF09B009CD09AC09BE099A09A8")]
Dict["party"] := [U("09AA09BE09B009CD099F09BF")]
Dict["court"] := [U("099509CB09B009CD099F")]
Dict["law"] := [U("0986098709A8")]
Dict["rule"] := [U("09A809BF09AF09BC09AE")]
Dict["system"] := [U("09B809BF09B809CD099F09C709AE")]
Dict["process"] := [U("09AA09CD09B009B809C709B8")]
Dict["program"] := [U("09AA09CD09B009CB099709CD09B009BE09AE")]
Dict["course"] := [U("099509CB09B009CD09B8")]
Dict["training"] := [U("099F09CD09B009C709A809BF0982")]
Dict["degree"] := [U("09A109BF099709CD09B009BF")]
Dict["diploma"] := [U("09A109BF09AA09CD09B209CB09AE09BE")]
Dict["admission"] := [U("09AD09B009CD09A409BF")]
Dict["fee"] := [U("09AB09BF")]
Dict["scholarship"] := [U("09AC09C309A409CD09A409BF")]
Dict["library"] := [U("09B209BE098709AC09CD09B009C709B009BF")]
Dict["science"] := [U("09AC09BF099C09CD099E09BE09A8")]
Dict["history"] := [U("098709A409BF09B909BE09B8")]
Dict["geography"] := [U("09AD09C2099709CB09B2")]
Dict["economics"] := [U("098509B009CD09A509A809C009A409BF")]
Dict["politics"] := [U("09B009BE099C09A809C009A409BF")]
Dict["religion"] := [U("09A709B009CD09AE")]
Dict["culture"] := [U("09B8098209B809CD099509C309A409BF")]
Dict["tradition"] := [U("099009A409BF09B909CD09AF")]
Dict["festival"] := [U("098909CE09B809AC")]
Dict["vacation"] := [U("099B09C1099F09BF")]
Dict["bridge"] := [U("09AC09CD09B009BF099C")]
Dict["building"] := [U("09AC09BF09B209CD09A109BF0982")]
Dict["floor"] := [U("09AB09CD09B209CB09B0")]
Dict["parking"] := [U("09AA09BE09B009CD099509BF0982")]
Dict["garage"] := [U("099709CD09AF09BE09B009C7099C")]
Dict["garden"] := [U("09AC09BE099709BE09A8")]
Dict["park"] := [U("09AA09BE09B009CD0995")]
Dict["lake"] := [U("09B209C70995")]
Dict["river"] := [U("09A809A609C0")]
Dict["sea"] := [U("09B809BE099709B0")]
Dict["beach"] := [U("09B809C8099509A4")]
Dict["island"] := [U("09A609CD09AC09C009AA")]
Dict["mountain"] := [U("09AA09BE09B909BE09A109BC")]
Dict["forest"] := [U("09AC09A8")]
Dict["tree"] := [U("099709BE099B")]
Dict["flower"] := [U("09AB09C109B2")]
Dict["animal"] := [U("09AA09B609C1")]
Dict["bird"] := [U("09AA09BE099609BF")]
Dict["dog"] := [U("099509C1099509C109B0")]
Dict["cat"] := [U("09AC09BF09A109BC09BE09B2")]
Dict["cow"] := [U("099709B009C1")]
Dict["goat"] := [U("099B09BE099709B2")]
Dict["horse"] := [U("099809CB09A109BC09BE")]
Dict["elephant"] := [U("09B909BE09A409BF")]
Dict["tiger"] := [U("09AC09BE0998")]
Dict["lion"] := [U("09B809BF098209B9")]
Dict["snake"] := [U("09B809BE09AA")]
Dict["monkey"] := [U("09AC09BE09A809B0")]
Dict["deer"] := [U("09B909B009BF09A3")]
Dict["rabbit"] := [U("099609B0099709CB09B6")]
Dict["duck"] := [U("09B909BE098109B8")]
Dict["hen"] := [U("09AE09C109B0099709BF")]
Dict["pig"] := [U("09B609C2099509B0")]
Dict["sheep"] := [U("09AD09C709A109BC09BE")]
Dict["camel"] := [U("0989099F")]
Dict["bear"] := [U("09AD09BE09B209C10995")]
Dict["fox"] := [U("09B609BF09AF09BC09BE09B2")]
Dict["wolf"] := [U("09A809C7099509A109BC09C7")]
Dict["rat"] := [U("0987098109A609C109B0")]
Dict["ant"] := [U("09AA09BF098109AA09A109BC09BE")]
Dict["bee"] := [U("09AE09CC09AE09BE099B09BF")]
Dict["butterfly"] := [U("09AA09CD09B0099C09BE09AA09A409BF")]
Dict["spider"] := [U("09AE09BE099509A109BC09B809BE")]
Dict["mosquito"] := [U("09AE09B609BE")]
Dict["fly"] := [U("09AE09BE099B09BF")]
Dict["frog"] := [U("09AC09CD09AF09BE0999")]
Dict["tortoise"] := [U("0995099A09CD099B09AA")]
Dict["crocodile"] := [U("099509C109AE09BF09B0")]
Dict["shark"] := [U("09B909BE099909B0")]
Dict["whale"] := [U("09A409BF09AE09BF")]
Dict["dolphin"] := [U("09A109B209AB09BF09A8")]
Dict["penguin"] := [U("09AA09C7099909CD099709C1098709A8")]
Dict["owl"] := [U("09AA09C70981099A09BE")]
Dict["eagle"] := [U("0988099709B2")]
Dict["crow"] := [U("099509BE0995")]
Dict["pigeon"] := [U("099509AC09C109A409B0")]
Dict["parrot"] := [U("099F09BF09AF09BC09BE")]
Dict["peacock"] := [U("09AE09AF09BC09C209B0")]
Dict["cuckoo"] := [U("099509CB099509BF09B2")]
Dict["sparrow"] := [U("099A09A109BC09C10987")]
Dict["ashlo"] := [U("098609B809B209CB")]
Dict["aslo"] := [U("098609B809B209CB")]
Dict["ashlam"] := [U("098609B809B209BE09AE")]
Dict["aslam"] := [U("098609B809B209BE09AE")]
Dict["ashlen"] := [U("098609B809B209C709A8")]
Dict["aslen"] := [U("098609B809B209C709A8")]
Dict["ashli"] := [U("098609B809B209BF")]
Dict["asli"] := [U("098609B809B209BF")]
Dict["asla"] := [U("098609B809B209BE")]
DictKeys := []
for k, v in Dict
    DictKeys.Push(k)

; ---------- sentence context (bigram + followers) ----------
Bigram := Map()
Bigram[U("09AE09CB09AC09BE098709B2") . "|deke"] := U("09A609C7099609BF")
Bigram[U("09B009BF09AA09CD09B209BE0987") . "|dei"] := U("09A609BF0987")
Bigram[U("098509B009CD09A109BE09B0") . "|nei"] := U("09A809BF0987")
Bigram[U("099C09BE09A809A409C7") . "|chaila"] := U("099A09BE098709B209C7")
Bigram[U("09AC09C709A109BC09C7") . "|jai"] := U("09AF09BE09AF09BC")
Bigram[U("09B909AF09BC09C7") . "|jai"] := U("09AF09BE09AF09BC")
Bigram[U("09B9099309AF09BC09BE") . "|jai"] := U("09AF09BE09AF09BC")
Bigram[U("099509AE09C709A809CD099F") . "|korla"] := U("099509B009B209C7")
Bigram[U("099609C109B609BF") . "|hoi"] := U("09B90987")
Bigram[U("098609AE09BF") . "|asi"] := U("0986099B09BF")
Bigram[U("09B009BE09A409C7") . "|chad"] := U("099A09BE098109A6")
Bigram[U("098B09A409C1") . "|asa"] := U("0986099B09C7")
Bigram[U("099509C309B70995") . "|mata"] := U("09AE09BE09A009C7")
Bigram[U("099509BE099C") . "|kora"] := U("099509B009C7")
Bigram[U("099509C709AE09A8") . "|aso"] := U("0986099B09CB")
Bigram[U("09A409C109AE09BF") . "|ki"] := U("099509C0")
Bigram[U("099509A509BE") . "|bolla"] := U("09AC09B209B209C7")
Bigram[U("09B609BF099509CD09B709BE") . "|sara"] := U("099B09BE09A109BC09BE")
Bigram[U("09AC0987") . "|kina"] := U("099509BF09A809C7")
Bigram[U("099509BF09A809C7") . "|ano"] := U("098F09A809CB")
Bigram[U("09AE09C709B809C7099C") . "|ar"] := U("098F09B0")
Bigram[U("09AC09BE098209B209BE09A609C709B6") . "|ar"] := U("098F09B0")
Bigram[U("09AC0987") . "|pore"] := U("09AA09A109BC09C7")
Bigram[U("099709B209CD09AA") . "|pore"] := U("09AA09A109BC09C7")
Bigram[U("099509AC09BF09A409BE") . "|pore"] := U("09AA09A109BC09C7")
Bigram[U("099A09BF09A009BF") . "|pore"] := U("09AA09A109BC09C7")
Bigram[U("098609AE09BF") . "|pore"] := U("09AA09B009C7")
Bigram[U("09A409C109AE09BF") . "|pore"] := U("09AA09B009C7")
Bigram[U("09B809C7") . "|pore"] := U("09AA09B009C7")
Bigram[U("09A409BE09B009BE") . "|pore"] := U("09AA09B009C7")
Bigram[U("098609AE09B009BE") . "|pore"] := U("09AA09B009C7")
Bigram[U("098609AE09BE09B0") . "|bon"] := U("09AC09CB09A8")
Bigram[U("09A409CB09AE09BE09B0") . "|bon"] := U("09AC09CB09A8")
Bigram[U("09A409BE09B0") . "|bon"] := U("09AC09CB09A8")
Bigram[U("09AC09A109BC") . "|bon"] := U("09AC09CB09A8")
Bigram[U("099B09CB099F") . "|bon"] := U("09AC09CB09A8")
Bigram[U("099C099909CD099709B2") . "|bon"] := U("09AC09A8")
Bigram[U("099709AD09C009B0") . "|bon"] := U("09AC09A8")
Bigram[U("098609AE09BF") . "|ashi"] := U("098609B809BF")
Bigram[U("09A409C109AE09BF") . "|ashi"] := U("098609B809BF")
Bigram[U("09AC09AF09BC09B8") . "|ashi"] := U("098609B609BF")
Bigram[U("098609AE09BE09B0") . "|pass"] := U("09AA09BE09B8099309AF09BC09BE09B009CD09A1")
Bigram[U("098609AE09BF") . "|pass"] := U("09AA09BE09B8")
Bigram[U("09AA09B009C0099509CD09B709BE") . "|pass"] := U("09AA09BE09B8")
Followers := Map()
Followers[U("099509C709AE09A8")] := [U("0986099B09CB"), U("0986099B09C709A8"), U("0986099B09BF09B8")]
Followers[U("098609AE09BF")] := [U("099509B009BF"), U("09AF09BE0987"), U("098609B809BF"), U("099609BE0987"), U("09A609C7099609BF"), U("09AC09B209BF"), U("099C09BE09A809BF"), U("09AC09C1099D09BF"), U("09AA09BE09B009BF"), U("099A09BE0987"), U("0986099B09BF"), U("09B209BF099609BF"), U("09AA09A109BC09BF"), U("09B609C109A809BF")]
Followers[U("09A409C109AE09BF")] := [U("099509B009CB"), U("09AF09BE0993"), U("098609B809CB"), U("099609BE0993"), U("09A609C7099609CB"), U("09AC09B209CB"), U("099C09BE09A809CB"), U("09AC09C1099D09CB"), U("09AA09BE09B009CB"), U("099A09BE0993"), U("0986099B09CB"), U("09B209BF099609CB"), U("09AA09A109BC09CB"), U("09B609C109A809CB")]
Followers[U("098609AA09A809BF")] := [U("099509B009C709A8"), U("09AF09BE09A8"), U("098609B809C109A8"), U("099609BE09A8"), U("09A609C7099609C109A8"), U("09AC09B209C109A8"), U("099C09BE09A809C709A8"), U("09AC09C1099D09C709A8"), U("09AA09BE09B009C709A8"), U("099A09BE09A8"), U("0986099B09C709A8"), U("09B209BF099609C109A8"), U("09AA09A109BC09C109A8"), U("09B609C109A809C109A8")]
Followers[U("09B809C7")] := [U("099509B009C7"), U("09AF09BE09AF09BC"), U("098609B809C7"), U("099609BE09AF09BC"), U("09A609C7099609C7"), U("09AC09B209C7"), U("099C09BE09A809C7"), U("09AC09C1099D09C7"), U("09AA09BE09B009C7"), U("099A09BE09AF09BC"), U("0986099B09C7"), U("09B209BF099609C7"), U("09AA09A109BC09C7"), U("09B609C109A809C7")]
Followers[U("09A409BE09B009BE")] := [U("099509B009C7"), U("09AF09BE09AF09BC"), U("098609B809C7"), U("099609BE09AF09BC"), U("09A609C7099609C7"), U("09AC09B209C7"), U("099C09BE09A809C7"), U("0986099B09C7")]
Followers[U("098609AE09B009BE")] := [U("099509B009BF"), U("09AF09BE0987"), U("098609B809BF"), U("099609BE0987"), U("09A609C7099609BF"), U("09AC09B209BF"), U("099C09BE09A809BF"), U("0986099B09BF")]
Followers[U("09A409CB09AE09B009BE")] := [U("099509B009CB"), U("09AF09BE0993"), U("098609B809CB"), U("099609BE0993"), U("09A609C7099609CB"), U("09AC09B209CB"), U("099C09BE09A809CB"), U("0986099B09CB")]
Followers[U("09A009BF0995")] := [U("0986099B09C7")]
Followers[U("09AD09BE09B209CB")] := [U("0986099B09BF"), U("0986099B09CB"), U("0986099B09C7"), U("09B209BE099709C7"), U("09B209BE0997099B09C7")]

; ---------- state & storage ----------
IniFile := A_ScriptDir . "\BanglaKeyboard.ini"
Enabled := true
Suspended := false
WordBuf := ""
Learned := Map()
ActiveProfile := U("098609AE09BF")
Profiles := []
LastWord := ""
LastConverted := ""
LastBoundary := ""
LearnedGuiOpen := false
SugList := []
SugVisible := false
PickResult := ""
PickDone := false
LastSugList := []
LastSugIdx := 0
PrevBangla := ""
ShowSugBox := false
SCRIPT_VERSION := 19
VER_URL := "https://raw.githubusercontent.com/gen26k-del/bangla-keyboard/main/version.txt"
FILE_URL := "https://raw.githubusercontent.com/gen26k-del/bangla-keyboard/main/BanglaKeyboard.ahk"
CoordMode("ToolTip", "Screen")
BoundaryChars := " .,!?;:'()[]{}<>/-_=+|@#$%^&*~" . Chr(34) . Chr(92) . Chr(96) . Chr(0x0964)

LoadSettings() {
    global IniFile, ActiveProfile, Enabled, ShowSugBox
    ActiveProfile := IniRead(IniFile, "Settings", "ActiveProfile", ActiveProfile)
    en := IniRead(IniFile, "Settings", "Enabled", "1")
    Enabled := (en == "1")
    sb := IniRead(IniFile, "Settings", "ShowSugBox", "0")
    ShowSugBox := (sb == "1")
    LoadProfiles()
    LoadLearned()
}

SaveSettings() {
    global IniFile, ActiveProfile, Enabled, ShowSugBox
    IniWrite(ActiveProfile, IniFile, "Settings", "ActiveProfile")
    IniWrite(Enabled ? "1" : "0", IniFile, "Settings", "Enabled")
    IniWrite(ShowSugBox ? "1" : "0", IniFile, "Settings", "ShowSugBox")
}

LoadProfiles() {
    global IniFile, Profiles, ActiveProfile
    Profiles := []
    secs := ""
    try {
        secs := IniRead(IniFile)
    } catch {
        secs := ""
    }
    for sec in StrSplit(secs, "`n") {
        if (SubStr(sec, 1, 8) == "Profile:")
            Profiles.Push(SubStr(sec, 9))
    }
    if (Profiles.Length == 0)
        Profiles.Push(ActiveProfile)
    found := false
    for p in Profiles {
        if (p == ActiveProfile)
            found := true
    }
    if (!found)
        Profiles.Push(ActiveProfile)
}

LoadLearned() {
    global IniFile, ActiveProfile, Learned
    Learned := Map()
    body := ""
    try {
        body := IniRead(IniFile, "Profile:" . ActiveProfile)
    } catch {
        body := ""
    }
    for line in StrSplit(body, "`n") {
        pos := InStr(line, "=")
        if (pos > 1)
            Learned[StrLower(SubStr(line, 1, pos - 1))] := SubStr(line, pos + 1)
    }
}

SwitchProfile(name) {
    global ActiveProfile
    ActiveProfile := name
    SaveSettings()
    LoadLearned()
    BuildTray()
    ToolTip(name)
    SetTimer(() => ToolTip(), -900)
}

NewProfile() {
    global Profiles, Suspended, ih
    Suspended := true
    ih.Stop()
    r := InputBox(U("09A809A409C109A8002009AA09CD09B009CB09AB09BE098709B209B0002009A809BE09AE002009B209BF099609C109A8"), U("09AA09CD09B009CB09AB09BE098709B2"), "w340")
    ih.Start()
    Suspended := false
    if (r.Result == "OK" && Trim(r.Value) != "") {
        name := Trim(r.Value)
        exists := false
        for p in Profiles {
            if (p == name)
                exists := true
        }
        if (!exists)
            Profiles.Push(name)
        SwitchProfile(name)
    }
}

ProfileMenuHandler(ItemName, ItemPos, MenuObj) {
    SwitchProfile(ItemName)
}

; ---------- typing / conversion ----------
ClearBuf() {
    global WordBuf, LastSugList, LastSugIdx, PrevBangla
    WordBuf := ""
    LastSugList := []
    LastSugIdx := 0
    PrevBangla := ""
    HideSug()
}

BufBackspace() {
    global WordBuf, LastSugList, LastSugIdx
    LastSugList := []
    LastSugIdx := 0
    if (WordBuf != "") {
        WordBuf := SubStr(WordBuf, 1, StrLen(WordBuf) - 1)
        if (WordBuf != "")
            ShowSug()
        else
            HideSug()
    }
}

ShowSug() {
    global WordBuf, SugList, SugVisible, ShowSugBox
    if (WordBuf == "") {
        HideSug()
        return
    }
    SugList := Suggest(WordBuf, 3, true)
    if (SugList.Length == 0) {
        HideSug()
        return
    }
    if (!ShowSugBox) {
        SugVisible := false
        return
    }
    txt := ""
    for i, s in SugList
        txt .= i . ". " . s . "`n"
    txt .= U("0054006100620020099A09BE09AA09B209C7002009E7002009A809AE09CD09AC09B0099F09BE002009AC09B809AC09C7")
    SugVisible := true
    ToolTip(txt, A_ScreenWidth // 2 - 110, A_ScreenHeight - 280)
}

HideSug() {
    global SugVisible, SugList
    SugVisible := false
    SugList := []
    ToolTip()
}

AcceptTopSug() {
    global WordBuf, SugList, SugVisible, LastWord, LastConverted, LastBoundary, Learned, ActiveProfile, IniFile, LastSugList, LastSugIdx, PrevBangla
    if (WordBuf == "" || SugList.Length == 0)
        return false
    chosen := SugList[1]
    LastSugList := SugList
    LastSugIdx := 1
    Send("{BS " . StrLen(WordBuf) . "}")
    SendText(chosen . " ")
    Learned[StrLower(WordBuf)] := chosen
    IniWrite(chosen, IniFile, "Profile:" . ActiveProfile, StrLower(WordBuf))
    LastWord := WordBuf
    LastConverted := chosen
    LastBoundary := " "
    PrevBangla := chosen
    WordBuf := ""
    SugVisible := false
    SugList := []
    ShowCycleTip()
    return true
}

CycleSug() {
    global LastSugList, LastSugIdx, LastWord, LastConverted, LastBoundary, Learned, ActiveProfile, IniFile, PrevBangla
    if (LastWord == "" || LastSugList.Length <= 1)
        return false
    LastSugIdx += 1
    if (LastSugIdx > LastSugList.Length)
        LastSugIdx := 1
    chosen := LastSugList[LastSugIdx]
    Send("{BS " . (StrLen(LastConverted) + StrLen(LastBoundary)) . "}")
    SendText(chosen . LastBoundary)
    Learned[StrLower(LastWord)] := chosen
    IniWrite(chosen, IniFile, "Profile:" . ActiveProfile, StrLower(LastWord))
    LastConverted := chosen
    PrevBangla := chosen
    ShowCycleTip()
    return true
}

ShowCycleTip() {
    global LastSugList, LastSugIdx, ShowSugBox
    if (!ShowSugBox)
        return
    txt := ""
    for i, s in LastSugList {
        mark := (i == LastSugIdx) ? "> " : "  "
        txt .= mark . i . ". " . s . "`n"
    }
    txt .= U("0054006100620020003D002009AA09B009C709B0002009B809BE099C09C709B609A8")
    ToolTip(txt, A_ScreenWidth // 2 - 110, A_ScreenHeight - 280)
}

TabHandler() {
    global Enabled, Suspended, WordBuf
    if (Enabled && !Suspended) {
        if (WordBuf != "" && AcceptTopSug())
            return
        if (WordBuf == "" && CycleSug())
            return
    }
    ClearBuf()
    Send("{Tab}")
}

CommitWord(boundary) {
    global WordBuf, LastWord, LastConverted, LastBoundary, LastSugList, LastSugIdx, PrevBangla
    HideSug()
    LastSugList := []
    LastSugIdx := 0
    if (WordBuf == "")
        return
    bn := Direct(WordBuf)
    Send("{BS " . (StrLen(WordBuf) + StrLen(boundary)) . "}")
    SendText(bn . boundary)
    LastWord := WordBuf
    LastConverted := bn
    LastBoundary := boundary
    PrevBangla := bn
    WordBuf := ""
}

CommitForEnter() {
    global WordBuf, LastWord, LastConverted, LastBoundary, Suspended, LastSugList, LastSugIdx, PrevBangla
    HideSug()
    LastSugList := []
    LastSugIdx := 0
    if (!Suspended && WordBuf != "") {
        bn := Direct(WordBuf)
        Send("{BS " . StrLen(WordBuf) . "}")
        SendText(bn)
        LastWord := WordBuf
        LastConverted := bn
        LastBoundary := ""
        PrevBangla := bn
        WordBuf := ""
    }
    Send("{Enter}")
}

CharHandler(ih, char) {
    global Enabled, Suspended, WordBuf, BoundaryChars, LastSugList, LastSugIdx
    if (!Enabled || Suspended)
        return
    if (char == "`r" || char == "`n")
        return
    if (RegExMatch(char, "^[A-Za-z0-9:]$")) {
        LastSugList := []
        LastSugIdx := 0
        WordBuf .= char
        ShowSug()
        return
    }
    if (InStr(BoundaryChars, char)) {
        CommitWord(char)
        return
    }
    WordBuf := ""
    HideSug()
}

ToggleMode() {
    global Enabled, WordBuf, LastSugList, LastSugIdx
    Enabled := !Enabled
    WordBuf := ""
    LastSugList := []
    LastSugIdx := 0
    HideSug()
    SaveSettings()
    BuildTray()
    ToolTip(Enabled ? U("09AC09BE098209B209BE") : "EN")
    SetTimer(() => ToolTip(), -900)
}

ToggleSugBox() {
    global ShowSugBox
    ShowSugBox := !ShowSugBox
    if (!ShowSugBox)
        HideSug()
    SaveSettings()
    BuildTray()
}

PickBangla(word, title) {
    global PickResult, PickDone
    PickResult := ""
    PickDone := false
    cands := Suggest(word, 8)
    g := Gui("+AlwaysOnTop", title)
    g.Add("Text", , U("09B809A009BF0995002009AC09BE098209B209BE099F09BE002009AC09C7099B09C7002009A809BF09A8"))
    lb := g.Add("ListBox", "w320 h170", cands)
    if (cands.Length > 0)
        lb.Choose(1)
    g.Add("Text", , U("098509A509AC09BE002000420061006E0067006C006900730068002D098F0020098509A809CD09AF002009AC09BE09A809BE09A809C7002009B209BF099609C109A8"))
    ed := g.Add("Edit", "w320", "")
    btnOk := g.Add("Button", "w100 Default", "OK")
    btnCancel := g.Add("Button", "x+10 w100", U("09AC09BE09A409BF09B2"))
    btnOk.OnEvent("Click", (*) => PickOk(lb, ed, g))
    lb.OnEvent("DoubleClick", (*) => PickOk(lb, ed, g))
    btnCancel.OnEvent("Click", (*) => PickCancel(g))
    g.OnEvent("Close", (*) => PickCancel(g))
    g.Show()
    WinWaitClose("ahk_id " . g.Hwnd)
    return PickResult
}

PickOk(lb, ed, g) {
    global PickResult, PickDone
    txt := Trim(ed.Value)
    if (txt != "")
        PickResult := PhoneticOrDict(txt)
    else if (lb.Value > 0)
        PickResult := lb.Text
    PickDone := true
    try {
        g.Destroy()
    } catch {
    }
}

PickCancel(g) {
    global PickResult, PickDone
    if (!PickDone)
        PickResult := ""
    try {
        g.Destroy()
    } catch {
    }
}

TeachWord() {
    global Learned, ActiveProfile, IniFile, Suspended, ih
    Suspended := true
    ih.Stop()
    HideSug()
    r1 := InputBox(U("00420061006E0067006C006900730068002009B609AC09CD09A6099F09BE002009B209BF099609C109A80020002809AF09C709AE09A8003A0020006C007900700074006F00700029"), U("09B609AC09CD09A6002009B609C7099609BE09A8"), "w340")
    if (r1.Result == "OK" && Trim(r1.Value) != "") {
        word := Trim(r1.Value)
        chosen := PickBangla(word, U("09B609AC09CD09A6002009B609C7099609BE09A8"))
        if (chosen != "") {
            key := StrLower(word)
            Learned[key] := chosen
            IniWrite(chosen, IniFile, "Profile:" . ActiveProfile, key)
            ToolTip(U("09B609C7099609BE002009B909AF09BC09C7099B09C7"))
            SetTimer(() => ToolTip(), -900)
        }
    }
    ih.Start()
    Suspended := false
}

FixLast() {
    global LastWord, LastConverted, LastBoundary, Learned, ActiveProfile, IniFile, Suspended, ih, PrevBangla
    if (LastWord == "") {
        ToolTip(U("0986099709C70020099509BF099B09C1002009B209BF099609C109A8"))
        SetTimer(() => ToolTip(), -900)
        return
    }
    Suspended := true
    ih.Stop()
    HideSug()
    chosen := PickBangla(LastWord, U("09B609C709B7002009B609AC09CD09A6002009A009BF09950020099509B009C109A8"))
    if (chosen != "") {
        key := StrLower(LastWord)
        Learned[key] := chosen
        IniWrite(chosen, IniFile, "Profile:" . ActiveProfile, key)
        Send("{BS " . (StrLen(LastConverted) + StrLen(LastBoundary)) . "}")
        SendText(chosen . LastBoundary)
        LastConverted := chosen
        PrevBangla := chosen
    }
    ih.Start()
    Suspended := false
}

; ---------- auto update ----------
CheckUpdate(manual := false) {
    global SCRIPT_VERSION, VER_URL, FILE_URL
    try {
        tmpVer := A_Temp . "\bk_ver.txt"
        Download(VER_URL . "?t=" . A_TickCount, tmpVer)
        newVer := Trim(FileRead(tmpVer))
        if (!IsInteger(newVer)) {
            if (manual)
                MsgBox(U("098609AA09A109C7099F0020099A09C709950020099509B009C109BE002009AF09BE09AF09BC09A809BF09640020098709A809CD099F09BE09B009A809C7099F0020099A09C709950020099509B009C109A80964"), "BanglaKeyboard", "Iconx")
            return
        }
        if (Integer(newVer) <= SCRIPT_VERSION) {
            if (manual)
                MsgBox(U("098609AA09A809BE09B00020099509BF09AC09CB09B009CD09A10020098609AA002D099F09C1002D09A109C7099F00200986099B09C70964"), "BanglaKeyboard", "Iconi")
            return
        }
        r := MsgBox(U("09A809A409C109A80020098609AA09A109C7099F00200986099B09C700210020098F099609A809870020098609AA09A109C7099F0020099509B009AC09C709A8003F"), "BanglaKeyboard", "YesNo Iconi")
        if (r != "Yes")
            return
        tmpFile := A_Temp . "\BanglaKeyboard_new.ahk"
        Download(FILE_URL . "?t=" . A_TickCount, tmpFile)
        content := FileRead(tmpFile)
        if (!InStr(content, "SCRIPT_VERSION")) {
            MsgBox(U("098609AA09A109C7099F002009AC09CD09AF09B009CD09A5002009B909AF09BC09C70964"), "BanglaKeyboard", "Iconx")
            return
        }
        FileCopy(A_ScriptFullPath, A_ScriptDir . "\BanglaKeyboard.bak.ahk", true)
        FileMove(tmpFile, A_ScriptFullPath, true)
        MsgBox(U("098609AA09A109C7099F002009B909AF09BC09C70020099709C7099B09C709640020099509BF09AC09CB09B009CD09A10020098609AC09BE09B00020099A09BE09B209C1002009B9099A09CD099B09C7002E002E002E"), "BanglaKeyboard", "Iconi")
        Reload()
    } catch {
        if (manual)
            MsgBox(U("098609AA09A109C7099F0020099A09C709950020099509B009C109BE002009AF09BE09AF09BC09A809BF09640020098709A809CD099F09BE09B009A809C7099F0020099A09C709950020099509B009C109A80964"), "BanglaKeyboard", "Iconx")
    }
}

; ---------- tray & learned-words window ----------
BuildTray() {
    global Enabled, Profiles, ActiveProfile, ShowSugBox
    toggleLabel := U("09AC09BE098209B209BE002009AE09CB09A10020099A09BE09B209C1002F09AC09A809CD09A700200028004600390029")
    A_TrayMenu.Delete()
    A_TrayMenu.Add(toggleLabel, (*) => ToggleMode())
    if (Enabled)
        A_TrayMenu.Check(toggleLabel)
    A_TrayMenu.Add()
    profMenu := Menu()
    for p in Profiles {
        profMenu.Add(p, ProfileMenuHandler)
        if (p == ActiveProfile)
            profMenu.Check(p)
    }
    profMenu.Add()
    profMenu.Add(U("09A809A409C109A8002009AA09CD09B009CB09AB09BE098709B2002E002E002E"), (*) => NewProfile())
    A_TrayMenu.Add(U("09AA09CD09B009CB09AB09BE098709B2"), profMenu)
    A_TrayMenu.Add(U("09B609C7099609BE002009B609AC09CD09A6002009A609C7099609C109A8"), (*) => ShowLearned())
    A_TrayMenu.Add(U("09B609C7099609BE09A800200028004300740072006C002B0041006C0074002B004C0029"), (*) => TeachWord())
    A_TrayMenu.Add(U("09B609C709B7002009B609AC09CD09A6002009A009BF09950020099509B009C109A800200028004300740072006C002B0041006C0074002B00460029"), (*) => FixLast())
    sugLabel := U("09B809BE099C09C709B609A8002009AC09BE099509CD09B8002009A609C7099609BE09A8")
    A_TrayMenu.Add(sugLabel, (*) => ToggleSugBox())
    if (ShowSugBox)
        A_TrayMenu.Check(sugLabel)
    A_TrayMenu.Add(U("098609AA09A109C7099F0020099A09C709950020099509B009C109A8"), (*) => CheckUpdate(true))
    A_TrayMenu.Add()
    A_TrayMenu.Add(U("09AC09A809CD09A70020099509B009C109A80020002800450078006900740029"), (*) => ExitApp())
    A_IconTip := Enabled ? U("00420061006E0067006C00610020004100490020004B006500790062006F00610072006400202014002009AC09BE098209B209BE002009AE09CB09A1") : U("00420061006E0067006C00610020004100490020004B006500790062006F0061007200640020201400200045006E0067006C006900730068002009AE09CB09A1")
}

ShowLearned() {
    global Learned, ActiveProfile, Suspended, ih, LearnedGuiOpen
    if (LearnedGuiOpen)
        return
    LearnedGuiOpen := true
    Suspended := true
    ih.Stop()
    g := Gui("+Resize", U("09B609C7099609BE002009B609AC09CD09A6") . " - " . ActiveProfile)
    lv := g.Add("ListView", "w460 h320", ["Banglish", U("09AC09BE098209B209BE")])
    for k, v in Learned
        lv.Add("", k, v)
    lv.ModifyCol(1, 180)
    lv.ModifyCol(2, 260)
    btnDel := g.Add("Button", "w120", U("09AE09C1099B09C109A8"))
    btnClose := g.Add("Button", "x+10 w120", U("09AC09A809CD09A70020099509B009C109A8"))
    btnDel.OnEvent("Click", (*) => DeleteSelected(lv))
    btnClose.OnEvent("Click", (*) => CloseLearned(g))
    g.OnEvent("Close", (*) => CloseLearned(g))
    g.Show()
}

DeleteSelected(lv) {
    global Learned, ActiveProfile, IniFile
    row := lv.GetNext()
    if (row == 0)
        return
    key := lv.GetText(row, 1)
    Learned.Delete(key)
    IniDelete(IniFile, "Profile:" . ActiveProfile, key)
    lv.Delete(row)
}

CloseLearned(g) {
    global Suspended, ih, LearnedGuiOpen
    if (!LearnedGuiOpen)
        return
    LearnedGuiOpen := false
    try {
        g.Destroy()
    } catch {
    }
    ih.Start()
    Suspended := false
}

; ---------- hotkeys ----------
F9:: {
    ToggleMode()
}
^!b:: {
    ToggleMode()
}
^!l:: {
    TeachWord()
}
^!f:: {
    FixLast()
}
$Enter:: {
    CommitForEnter()
}
$NumpadEnter:: {
    CommitForEnter()
}
~Backspace:: {
    BufBackspace()
}
~Left:: {
    ClearBuf()
}
~Right:: {
    ClearBuf()
}
~Up:: {
    ClearBuf()
}
~Down:: {
    ClearBuf()
}
~Home:: {
    ClearBuf()
}
~End:: {
    ClearBuf()
}
~Delete:: {
    ClearBuf()
}
$Tab:: {
    TabHandler()
}
~Esc:: {
    ClearBuf()
}
~LButton:: {
    ClearBuf()
}
~RButton:: {
    ClearBuf()
}
~MButton:: {
    ClearBuf()
}
~^v:: {
    ClearBuf()
}
~^x:: {
    ClearBuf()
}
~^a:: {
    ClearBuf()
}
~^w:: {
    ClearBuf()
}
~^t:: {
    ClearBuf()
}
~^z:: {
    ClearBuf()
}
~^y:: {
    ClearBuf()
}
~^Backspace:: {
    ClearBuf()
}
~^Delete:: {
    ClearBuf()
}
~^Left:: {
    ClearBuf()
}
~^Right:: {
    ClearBuf()
}
~^Up:: {
    ClearBuf()
}
~^Down:: {
    ClearBuf()
}

; ---------- start ----------
Persistent()
LoadSettings()
if (FileExist(A_ScriptDir . "\icon.ico"))
    TraySetIcon(A_ScriptDir . "\icon.ico")
BuildTray()
ih := InputHook("I1 V")
ih.OnChar := CharHandler
ih.Start()
SetTimer(() => CheckUpdate(false), -8000)
