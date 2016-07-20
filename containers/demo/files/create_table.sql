-- --------------------------------------------------------

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Database: `cakephp2`
--
CREATE DATABASE IF NOT EXISTS `cakephp` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `cakephp`;

-- --------------------------------------------------------

--
-- テーブルの構造 `post`
--

CREATE TABLE IF NOT EXISTS `posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `post` text NOT NULL,
  `user_id` INT(11),
  `created` datetime NOT NULL,
  `modified` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;

--
-- テーブルの構造 `user`
--
CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(255),
    role VARCHAR(20),
    created DATETIME DEFAULT NULL,
    modified DATETIME DEFAULT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;

INSERT INTO `users` VALUES (1,'toubaru','$2a$10$dfIFgR/wHc4SJYeYNJMUmO08PuIqPz.Cog543Wo.dQZCuT1uTCQ9y','author','2016-07-19 09:44:40','2016-07-19 09:44:40');

-- --------------------------------------------------------