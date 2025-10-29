const db = require("../models");
const Users = db.Users;
const bcrypt = require("bcrypt");
const {
  NotFoundError,
  BadRequestError,
  UnauthorizedError,
} = require("../../expressError");
const userRegisterSchema = require("../schemas/userRegister.json");
const userAuthSchema = require("../schemas/userAuth.json");
const userEditSchema = require("../schemas/userEdit.json");

const { BCRYPT_WORK_FACTOR } = require("../../config.js");
const jsonschema = require("jsonschema");
const { createToken } = require("../helpers/token");

//Create a New User
exports.create = async (req, res, next) => {
  const validator = jsonschema.validate(req.body, userRegisterSchema);
  if (!validator.valid) {
    const errs = validator.errors.map((e) => e.stack);
    return next(new BadRequestError(errs));
  }

  // Check if user already exists
  const existingUser = await Users.findOne({ email: req.body.email });
  if (existingUser) {
    return next(new BadRequestError("User with this email already exists"));
  }

  let hashedPassword = await bcrypt.hash(req.body.password, BCRYPT_WORK_FACTOR);

  const newUser = new Users({
    firstName: req.body.firstName,
    lastName: req.body.lastName,
    email: req.body.email,
    password: hashedPassword,
    isAdmin: false,
  });
  const token = createToken(newUser);

  try {
    await newUser.save();
    res.status(201).send({ token });
  } catch (err) {
    return next(err);
  }
};

exports.authenticate = async (req, res, next) => {
  const validator = jsonschema.validate(req.body, userAuthSchema);
  if (!validator.valid) {
    const errs = validator.errors.map((e) => e.stack);
    return next(new BadRequestError(errs));
  }

  const { email, password } = req.body;

  let user = await Users.findOne({
    email: email,
  });

  if (user) {
    const isValid = await bcrypt.compare(password, user.password);
    if (isValid === true) {
      const token = createToken(user);
      return res.status(200).json({ token });
    } else {
      return next(new UnauthorizedError());
    }
  }

  return next(new NotFoundError());
};

exports.getAllUsers = async (req, res, next) => {
  try {
    let users = await Users.find();
    const usersWithoutPasswords = users.map(user => {
      const userObj = user.toObject();
      delete userObj.password;
      return userObj;
    });
    return res.json({ users: usersWithoutPasswords });
  } catch (err) {
    return next(err);
  }
};

exports.getAUser = async (req, res, next) => {
  let email = req.params.email;

  let user = await Users.findOne({
    email: email,
  });

  if (user) {
    const userObj = user.toObject();
    delete userObj.password;
    return res.status(200).json({ user: userObj });
  }

  return next(new NotFoundError());
};

exports.updateAUser = async (req, res, next) => {
  const validator = jsonschema.validate(req.body, userEditSchema);

  if (!validator.valid) {
    const errs = validator.errors.map((e) => e.stack);
    return next(new BadRequestError(errs));
  }

  let hashedPassword = await bcrypt.hash(req.body.password, BCRYPT_WORK_FACTOR);

  try {
    const result = await Users.updateOne(
      { email: req.params.email },
      {
        firstName: req.body.firstName,
        lastName: req.body.lastName,
        password: hashedPassword,
      }
    );

    if (result.matchedCount === 0) {
      return next(new NotFoundError());
    }

    const updatedUser = await Users.findOne({ email: req.params.email });
    const userObj = updatedUser.toObject();
    delete userObj.password;
    res.status(200).send({ user: userObj });
  } catch (err) {
    return next(err);
  }
};

exports.removeAUser = async (req, res, next) => {
  try {
    const result = await Users.deleteOne({ email: req.params.email });
    if (result.deletedCount === 0) {
      return next(new NotFoundError());
    }
    res.status(200).send({ message: "successfully deleted" });
  } catch (err) {
    return next(err);
  }
};
