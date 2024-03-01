`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output filter_done);

// Definitii ale starilor
localparam STATE_IDLE = 0,
           STATE_MIRROR = 1,
           STATE_GRAYSCALE = 2,
           STATE_SHARPNESS = 3,
           STATE_DONE = 4;

reg [2:0] state, next_state;

//STATE_MIRROR
reg [5:0] read_row, read_col; // citirea pixelului
reg [5:0] write_row, write_col; // Scrierea pixelu


//STATE_GRAYSCALE
reg [7:0] red, green, blue;
reg [7:0] max_color, min_color, gray_value;

// Logica de tranzitie a starilor
always @(posedge clk) begin
    if (reset) 
        state <= STATE_IDLE;
    else 
        state <= next_state;
end

// Logica pentru fiecare stare
always @(*) begin
    case (state)
        STATE_IDLE: begin
            // Initializare
            next_state = STATE_MIRROR;
        end
        STATE_MIRROR: begin //citirea pixelilor din imaginea originala si scrierea lor in locatiile corespunzatoare inversate in imaginea de iesire
            if (state == STATE_MIRROR) begin
			// Setam coordonatele de citire
			read_row <= row;
			read_col <= col;

			// Calculam coordonatele de scriere pentru oglindire
			write_row <= row;
			write_col <= 63 - col;

			// Citim pixelul din imaginea originala
			// (Presupunem ca in_pix este conectat la iesirea modulului de imagine)
			// in_pix <= imagine[read_row][read_col];

			// Scriem pixelul in pozitia oglindita
			out_pix <= in_pix; // Presupunem ca out_pix este conectat la intrarea modulului de imagine
			out_we <= 1; // Activam scrierea

			// Actualizam coloana pentru urmatoarea iteratie
			if (col < 63)
				col <= col + 1;
			else if (row < 63) begin
				row <= row + 1;
				col <= 0;
			end else begin
				// Finalizam procesul de oglindire
				mirror_done <= 1;
				next_state <= STATE_GRAYSCALE;
			end
				// Tranzitie la urmatoarea stare
				next_state = mirror_done ? STATE_GRAYSCALE : STATE_MIRROR;
			end
		end
        STATE_GRAYSCALE: begin
            if (state == STATE_MIRROR) begin // transformare va fi aplicata pe imaginea deja oglindita.
			//coordonatele de citire
			read_row <= row;
			read_col <= col;

			// Calculam coordonatele de scriere pentru oglindire
			write_row <= row;
			write_col <= 63 - col;

			// Citim pixelul din imaginea originala
			// (Presupunem ca in_pix este conectat la iesirea modulului de imagine)
			// in_pix <= imagine[read_row][read_col];

			// Scriem pixelul in pozitia oglindita
			out_pix <= in_pix; // Presupunem ca out_pix este conectat la intrarea modulului de imagine
			out_we <= 1; // Activam scrierea

			// Actualizam coloana pentru urmatoarea iteratie
			if (col < 63)
				col <= col + 1;
			else if (row < 63) begin
				row <= row + 1;
				col <= 0;
			end else begin
				// OGLINDIRE -> DONE - go next state
				mirror_done <= 1;
				next_state <= STATE_GRAYSCALE;
			end
			end
            // next state
            next_state = gray_done ? STATE_SHARPNESS : STATE_GRAYSCALE;
        end
        STATE_SHARPNESS: begin
            // ...
            // Tranzitie la urmatoarea stare
            next_state = filter_done ? STATE_DONE : STATE_SHARPNESS;
        end
        STATE_DONE: begin
            // done
        end
        default: next_state = STATE_IDLE;
    endcase
end


endmodule
