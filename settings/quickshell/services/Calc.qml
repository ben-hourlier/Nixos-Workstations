pragma Singleton

import Quickshell
import QtQuick

// Calculator of the app launcher: a small recursive-descent parser, never
// eval. Numbers take "." or "," as the decimal point; operators + - * / % ^
// (also x and ×), parentheses, constants pi and e, and the functions below.
// Only expressions with a digit and an operator or function count: a bare
// number or a word stays an app search.
Singleton {
    id: root

    readonly property var functions: ({
            sqrt: Math.sqrt,
            abs: Math.abs,
            round: Math.round,
            floor: Math.floor,
            ceil: Math.ceil,
            ln: Math.log,
            log: Math.log10,
            exp: Math.exp,
            sin: Math.sin,
            cos: Math.cos,
            tan: Math.tan,
            asin: Math.asin,
            acos: Math.acos,
            atan: Math.atan
        })
    readonly property var constants: ({
            pi: Math.PI,
            e: Math.E
        })

    // Formatted result, or "" when the text is not a calculation.
    function evaluate(text: string): string {
        const tokens = tokenize(text);
        if (!tokens || !/\d/.test(text) || !tokens.some(t => t.type === "fn" || (t.type === "op" && !"()".includes(t.value))))
            return "";
        let pos = 0;
        const peek = () => tokens[pos] ?? { type: "end" };
        const take = () => tokens[pos++];
        const isOp = (...ops) => peek().type === "op" && ops.includes(peek().value);

        // expr := term (("+" | "-") term)*
        function expr() {
            let v = term();
            while (isOp("+", "-"))
                v = take().value === "+" ? v + term() : v - term();
            return v;
        }
        // term := unary (("*" | "/" | "%") unary)*
        function term() {
            let v = unary();
            while (isOp("*", "/", "%")) {
                const op = take().value;
                const r = unary();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        // unary := ("-" | "+") unary | power
        function unary() {
            if (isOp("-", "+"))
                return take().value === "-" ? -unary() : unary();
            return power();
        }
        // power := atom ("^" unary)?   (right-associative)
        function power() {
            const v = atom();
            if (isOp("^")) {
                take();
                return Math.pow(v, unary());
            }
            return v;
        }
        // atom := number | constant | fn atom | "(" expr ")"
        function atom() {
            const t = take();
            if (!t)
                throw "end";
            if (t.type === "num" || t.type === "const")
                return t.value;
            if (t.type === "fn")
                return t.value(atom());
            if (t.type === "op" && t.value === "(") {
                const v = expr();
                if (!isOp(")"))
                    throw "paren";
                take();
                return v;
            }
            throw "token";
        }

        try {
            const v = expr();
            if (pos !== tokens.length || !isFinite(v))
                return "";
            return format(v);
        } catch (e) {
            return "";
        }
    }

    function tokenize(text: string): var {
        const tokens = [];
        const re = /\s*(?:(\d+(?:[.,]\d*)?|[.,]\d+)|([a-z]+)|([-+*\/%^()×÷]))/gy;
        const source = text.toLowerCase().trim();
        let m;
        while (re.lastIndex < source.length && (m = re.exec(source))) {
            if (m[1] !== undefined) {
                tokens.push({ type: "num", value: parseFloat(m[1].replace(",", ".")) });
            } else if (m[2] !== undefined) {
                if (m[2] === "x")
                    tokens.push({ type: "op", value: "*" });
                else if (m[2] in functions)
                    tokens.push({ type: "fn", value: functions[m[2]] });
                else if (m[2] in constants)
                    tokens.push({ type: "const", value: constants[m[2]] });
                else
                    return null;
            } else {
                const op = { "×": "*", "÷": "/" }[m[3]] ?? m[3];
                tokens.push({ type: "op", value: op });
            }
        }
        return re.lastIndex >= source.length ? tokens : null;
    }

    // 12 significant digits, without float noise such as 0.1 + 0.2.
    function format(v: real): string {
        return String(parseFloat(v.toPrecision(12)));
    }
}
