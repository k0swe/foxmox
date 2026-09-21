#!/usr/bin/env python3

import unittest

import emit_callsign


class EmitCallsignTests(unittest.TestCase):
    def test_default_callsign_and_padding(self) -> None:
        source = emit_callsign.render("N0PUF")
        self.assertIn("; Build-time callsign: N0PUF", source)
        self.assertEqual(source.count("CALL      send_morse_"), 5)
        self.assertEqual(source.count("DW        0x3FFF"), 117)

    def test_length_changes_are_offset_by_padding(self) -> None:
        four = emit_callsign.render("W0QE")
        six = emit_callsign.render("K0SWE1")
        self.assertEqual(four.count("CALL      send_morse_"), 4)
        self.assertEqual(four.count("DW        0x3FFF"), 118)
        self.assertEqual(six.count("CALL      send_morse_"), 6)
        self.assertEqual(six.count("DW        0x3FFF"), 116)

    def test_input_is_normalized_to_uppercase(self) -> None:
        source = emit_callsign.render(" k0swe ")
        self.assertIn("; Build-time callsign: K0SWE", source)
        self.assertIn("CALL      send_morse_k", source)
        self.assertIn("CALL      send_morse_0", source)

    def test_rejects_unsupported_characters(self) -> None:
        for callsign in ("", "N0/PUF", "N0 PUF", "N0_PUF"):
            with self.subTest(callsign=callsign):
                with self.assertRaises(ValueError):
                    emit_callsign.render(callsign)

    def test_rejects_callsign_that_exhausts_program_memory(self) -> None:
        with self.assertRaises(ValueError):
            emit_callsign.render("A" * (emit_callsign.MAX_CALLSIGN_LENGTH + 1))


if __name__ == "__main__":
    unittest.main()
