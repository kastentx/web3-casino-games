import random

def roll_dice():
    """Simulate rolling two six-sided dice."""
    return random.randint(1, 6), random.randint(1, 6)

def print_roll(die1, die2):
    """Print the result of the dice roll."""
    print(f"You rolled a {die1} and a {die2} (total: {die1 + die2})")

def play_craps():
    """Play a game of craps."""
    print("Welcome to Craps!")
    
    die1, die2 = roll_dice()
    first_roll_total = die1 + die2
    print_roll(die1, die2)
    
    if first_roll_total in (7, 11):
        print("Congratulations! You win!")
        return True
    elif first_roll_total in (2, 3, 12):
        print("Craps! You lose.")
        return False
    else:
        point = first_roll_total
        print(f"Your point is {point}. Keep rolling!")
        
        while True:
            die1, die2 = roll_dice()
            roll_total = die1 + die2
            print_roll(die1, die2)
            
            if roll_total == point:
                print("You hit your point! You win!")
                return True
            elif roll_total == 7:
                print("Seven out! You lose.")
                return False

if __name__ == "__main__":
    play_craps()