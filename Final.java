import java.io.File;
import java.util.Scanner;

public class Final {
	
	public static void main(String[] args) throws Exception {
		Scanner fileScanner = new Scanner(new File("Sudoku.txt"));
		int[] sudoku = new int[81]; 
		String line = fileScanner.nextLine();
		int x = 0;
		// getting Sudoku puzzle from the a file and 
		// store the puzzle in sudoku array
		// 0 in a box means the box is unknown
		for (int i = 0; i < 81; i++) {
			sudoku[i] = Character.getNumericValue(line.charAt(x));
			x++;
			if (x == 9 && fileScanner.hasNextLine()) {
				line = fileScanner.nextLine();
				x = 0;
			}
		}
		// call solve funtion to find the solution
		// passing work positon 0, to start the searching
		// when solution is found, true is returned and 
		// the answer is printed out, otherwise print "No solution"
		if (solve(sudoku, 0)) {
			printSudoku(sudoku);
		} else {
			System.out.println("No solution");
		}
		fileScanner.close();

	}
	// recursive call to find a solution for a puzzle stored in sudoku array
	// the current working index is i
	// return true is solution is found
	private static boolean solve(int[] sudoku, int i) {
		// base case for recursion
		// if the working position 81 is being call
		// we have been successfully fill all the box from index 0 to 80
		// then we found the solution
		if (i >= 81) {
			return true;
		} else {
			// get the next working postion
			int newI = i + 1;
			// at the current positon, the value for the box is already give
			// skip this position, recursive call to work on the next working position
			if (sudoku[i] != 0) {
				return solve(sudoku, newI);
			} else {
				// the current positon is unknown
				// get the corresponding X and Y coordinate
				int cellY = getY(i);
				int cellX = getX(i, cellY);
				// loop to try all digits from 1 to 9
				for (int checkNum = 1; checkNum < 10; checkNum++) {
					// if the digits does not violate the rule
					if (checkSquare(sudoku, cellX, cellY, checkNum) && checkRow(sudoku, cellY, checkNum)
							&& checkCol(sudoku, cellX, checkNum)) {
						// fill the tried number in the sudoku array
						sudoku[i] = checkNum;
						// recursive call to working on next position
						if (solve(sudoku, newI)) {
							return true;
						}
					}
				}
				// after the loop there is noway to find a digit without violating the rule
				// undo the changes to the current positon by resetting 0 to current position
				sudoku[i] = 0;
				// no solution can be found, goting the back to previous call to try next digit
				return false;
			}
		}
	}
	// get X coordinate
	private static int getX(int i, int y) {
		return (i - y * 9);
	}
	// get Y coordinate
	private static int getY(int i) {
		if (i <= 8) {
			return 0;
		} else if (i <= 17) {
			return 1;
		} else if (i <= 26) {
			return 2;
		} else if (i <= 35) {
			return 3;
		} else if (i <= 44) {
			return 4;
		} else if (i <= 53) {
			return 5;
		} else if (i <= 62) {
			return 6;
		} else if (i <= 71) {
			return 7;
		} else {
			return 8;
		}
	}
	// is digit toCheck valid at (reqX, reqY) in its sub-grid
	private static boolean checkSquare(int[] sudoku, int reqX, int reqY, int toCheck) {
		// colX and rowY are the coordinate of the top-left corner in the sub-grid
		int rowY;
		int colX;
		if (reqX < 3) {
			colX = 0;
		} else if (reqX < 6) {
			colX = 3;
		} else {
			colX = 6;
		}
		if (reqY < 3) {
			rowY = 0;
		} else if (reqY < 6) {
			rowY = 3;
		} else {
			rowY = 6;
		}
		// the 1D index of the top-left corner in the sub-grid
		int i = colX + rowY * 9;
		int k = 0;
		// the loop traverse all elements in the sub-grid
		for (int j = 0; j < 9; j++) {
			k++;
			if (sudoku[i] == toCheck) {
				return false;
			}
			if (k == 3) {
				k = 0;
				i = i + 7;
			} else {
				i = i + 1;
			}
		}
		return true;
	}
	// is digit toCheck valid in rowY
	private static boolean checkRow(int[] sudoku, int rowY, int toCheck) {
		// the index of the left most element in rowY
		int i = rowY * 9;
		// the loop traverse all elements in rowY
		for (int x = 0; x < 9; x++) {
			if (toCheck == sudoku[i]) {
				return false;
			}
			i++;
		}
		return true;
	}
	// is digit toCheck valid in colX
	private static boolean checkCol(int[] sudoku, int colX, int toCheck) {
		// the loop traverse all elements in colX
		for (int y = 0; y < 9; y++) {
			if (toCheck == sudoku[colX]) {
				return false;
			}
			colX = colX + 9;
		}
		return true;
	}

	private static void printSudoku(int sudoku[]) {
		int x = 0;
		for (int i = 0; i < 81; i++) {
			System.out.print(sudoku[i]);
			x++;
			if (x == 9) {
				System.out.println();
				x = 0;
			}
		}
	}
}