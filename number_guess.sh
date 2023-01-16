#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "\nNumber Guessing Game\n"

echo "Enter your username:"
read USERNAME

USERNAME_SEARCH=$($PSQL "SELECT * FROM users WHERE username='$USERNAME'")
if [[ -z $USERNAME_SEARCH ]]
then
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  USER_INSERT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  # <games_played>: being the total number of games that user has played.
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")

  # <best_game>: being the fewest number of guesses it took that user to win the game.
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID")

  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Loading game
RANDOM_NUMBER=$((1 + $RANDOM % 1000))
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
NEW_GAME=$($PSQL "INSERT INTO games(secret_number, user_id) VALUES($RANDOM_NUMBER, $USER_ID)")
GAME_ID=$($PSQL "SELECT game_id FROM games WHERE secret_number=$RANDOM_NUMBER AND user_id=$USER_ID")

 echo "RANDOM_NUMBER is $RANDOM_NUMBER, for testing."
echo -e "\nGuess the secret number between 1 and 1000:\n"

# register number of guessing
COUNT=0

EVALUATE(){
  read GUESSING

  # That is not an integer, guess again:
  REGEX='^[0-9]+$'
  if ! [[ $GUESSING =~ $REGEX ]]
  then
    echo -e "That is not an integer, guess again:\n"
    EVALUATE
  fi

  # GUESSING > RANDOM_NUMBER
  if [[ $GUESSING > $RANDOM_NUMBER ]]
  then
    echo -e "It's lower than that, guess again:\n"
    ((++COUNT))
    EVALUATE
  fi

  # GUESSING < RANDOM_NUMBER
  if [[ $GUESSING < $RANDOM_NUMBER ]]
  then
    echo -e "It's higher than that, guess again:\n"
    ((++COUNT))
    EVALUATE
  fi

  # GUESSING = RANDOM_NUMBER
  if [[ $GUESSING == $RANDOM_NUMBER ]]
  then
    ((++COUNT))
    NUMBER_OF_GUESSES_INSERT=$($PSQL "UPDATE games SET number_of_guesses = $COUNT WHERE game_id=$GAME_ID")

    echo -e "You guessed it in $COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
    exit
  fi
}
EVALUATE

# Clear db: TRUNCATE users RESTART IDENTITY CASCADE;