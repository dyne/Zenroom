/*
 * DECODE App – A mobile app to control your personal data
 *
 * Copyright (C) 2019 – DRIBIA Data Research S.L.
 *
 * DECODE App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * DECODE App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * email: info@dribia.com
 */

/**
 * This class contains the JNI bindings for the native Zenroom library.
 * It's package and method names are tied to it, be careful if you need changing them
 */

package decode.zenroom;



public class Zenroom {

    public native String zenroom(String script, String conf, String key, String data);

    public String execute(String script, String conf, String key, String data) {
        return zenroom(script, conf, key, data);
    }
}
